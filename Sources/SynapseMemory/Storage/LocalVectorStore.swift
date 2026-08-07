import Foundation
import GRDB
import Accelerate

/// Concrete local database store backed by SQLite (via GRDB) and Accelerate framework SIMD vector operations.
/// Supports Core Memories, Knowledge Graph, Documents/Bookmarks (Supermemory), Recall Dialogue Logs (Letta), and Summaries (Zep).
public actor LocalVectorStore: VectorStore {
    private let dbQueue: DatabaseQueue
    private let alpha: Float // Vector similarity weight (default 0.7)
    private let beta: Float  // BM25 text rank weight (default 0.3)
    private let decayLambda: Float // Time decay factor (per day, default 0.01)

    public init(
        databasePath: String? = nil,
        alpha: Float = 0.7,
        beta: Float = 0.3,
        decayLambda: Float = 0.01
    ) throws {
        self.alpha = alpha
        self.beta = beta
        self.decayLambda = decayLambda
        
        let path: String
        if let databasePath = databasePath {
            path = databasePath
        } else {
            let fileManager = FileManager.default
            let urls = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)
            let appSupportDir = urls.first ?? fileManager.temporaryDirectory
            let synapseDir = appSupportDir.appendingPathComponent("SynapseMemory", isDirectory: true)
            try fileManager.createDirectory(at: synapseDir, withIntermediateDirectories: true)
            path = synapseDir.appendingPathComponent("synapse.sqlite").path
        }
        
        self.dbQueue = try DatabaseQueue(path: path)
        try Self.setupSchema(dbQueue: dbQueue)
    }

    /// In-memory database initializer for testing.
    public init(inMemory: Bool, alpha: Float = 0.7, beta: Float = 0.3, decayLambda: Float = 0.01) throws {
        self.alpha = alpha
        self.beta = beta
        self.decayLambda = decayLambda
        self.dbQueue = try DatabaseQueue()
        try Self.setupSchema(dbQueue: dbQueue)
    }

    private static func setupSchema(dbQueue: DatabaseQueue) throws {
        var migrator = DatabaseMigrator()
        
        migrator.registerMigration("v1_create_tables") { db in
            // Primary Memories Table
            try db.create(table: "memories") { t in
                t.column("id", .text).primaryKey()
                t.column("memory", .text).notNull()
                t.column("hash", .text).notNull()
                t.column("vectorData", .blob)
                t.column("userId", .text)
                t.column("agentId", .text)
                t.column("runId", .text)
                t.column("metadataJson", .text)
                t.column("validFrom", .double).notNull()
                t.column("validTo", .double)
                t.column("supersededById", .text)
                t.column("accessCount", .integer).notNull().defaults(to: 0)
                t.column("lastAccessedAt", .double).notNull()
                t.column("scoreWeight", .double).notNull().defaults(to: 1.0)
                t.column("createdAt", .double).notNull()
                t.column("updatedAt", .double).notNull()
                t.column("isDeleted", .boolean).notNull().defaults(to: false)
                t.column("version", .integer).notNull().defaults(to: 1)
                t.column("syncState", .text).notNull().defaults(to: "pendingUpload")
            }
            
            // FTS5 Virtual Table for BM25 text search
            try db.execute(sql: """
                CREATE VIRTUAL TABLE IF NOT EXISTS memories_fts USING fts5(
                    id UNINDEXED,
                    memory,
                    tokenize = 'porter unicode61'
                );
            """)
            
            // Audit History Table
            try db.create(table: "memory_history") { t in
                t.column("id", .text).primaryKey()
                t.column("memoryId", .text).notNull()
                t.column("action", .text).notNull()
                t.column("oldMemory", .text)
                t.column("newMemory", .text)
                t.column("timestamp", .double).notNull()
                t.column("userId", .text)
            }
            
            // Core Working Memory Blocks Table
            try db.create(table: "core_memory_blocks") { t in
                t.column("blockKey", .text).primaryKey()
                t.column("blockValue", .text).notNull()
                t.column("updatedAt", .double).notNull()
            }
        }

        migrator.registerMigration("v2_add_supermemory_and_zep_tables") { db in
            // Documents & Bookmarks Table (Supermemory)
            try db.create(table: "documents") { t in
                t.column("id", .text).primaryKey()
                t.column("title", .text).notNull()
                t.column("url", .text)
                t.column("content", .text).notNull()
                t.column("chunkIndex", .integer).notNull().defaults(to: 0)
                t.column("totalChunks", .integer).notNull().defaults(to: 1)
                t.column("vectorData", .blob)
                t.column("tagsJson", .text)
                t.column("userId", .text)
                t.column("metadataJson", .text)
                t.column("createdAt", .double).notNull()
                t.column("updatedAt", .double).notNull()
                t.column("isDeleted", .boolean).notNull().defaults(to: false)
            }

            // Recall Message Log Table (Letta/MemGPT)
            try db.create(table: "recall_messages") { t in
                t.column("id", .text).primaryKey()
                t.column("role", .text).notNull()
                t.column("content", .text).notNull()
                t.column("userId", .text)
                t.column("agentId", .text)
                t.column("runId", .text)
                t.column("timestamp", .double).notNull()
            }

            // Conversation Summaries Table (Zep)
            try db.create(table: "conversation_summaries") { t in
                t.column("id", .text).primaryKey()
                t.column("userId", .text)
                t.column("agentId", .text)
                t.column("runId", .text)
                t.column("summary", .text).notNull()
                t.column("messageCount", .integer).notNull().defaults(to: 0)
                t.column("lastMessageTimestamp", .double).notNull()
                t.column("createdAt", .double).notNull()
                t.column("updatedAt", .double).notNull()
            }
        }
        
        try migrator.migrate(dbQueue)
    }

    // MARK: - VectorStore Implementation

    public func save(item: MemoryItem) async throws {
        try await saveBatch(items: [item])
    }

    public func saveBatch(items: [MemoryItem]) async throws {
        try await dbQueue.write { db in
            for item in items {
                let vectorData = Data(bytes: item.vector, count: item.vector.count * MemoryLayout<Float>.size)
                let metadataData = try JSONEncoder().encode(item.metadata)
                let metadataJson = String(data: metadataData, encoding: .utf8) ?? "{}"

                try db.execute(
                    sql: """
                    INSERT INTO memories (
                        id, memory, hash, vectorData, userId, agentId, runId, metadataJson,
                        validFrom, validTo, supersededById, accessCount, lastAccessedAt,
                        scoreWeight, createdAt, updatedAt, isDeleted, version, syncState
                    ) VALUES (
                        ?, ?, ?, ?, ?, ?, ?, ?,
                        ?, ?, ?, ?, ?,
                        ?, ?, ?, ?, ?, ?
                    ) ON CONFLICT(id) DO UPDATE SET
                        memory = excluded.memory,
                        hash = excluded.hash,
                        vectorData = excluded.vectorData,
                        userId = excluded.userId,
                        agentId = excluded.agentId,
                        runId = excluded.runId,
                        metadataJson = excluded.metadataJson,
                        validFrom = excluded.validFrom,
                        validTo = excluded.validTo,
                        supersededById = excluded.supersededById,
                        accessCount = excluded.accessCount,
                        lastAccessedAt = excluded.lastAccessedAt,
                        scoreWeight = excluded.scoreWeight,
                        updatedAt = excluded.updatedAt,
                        isDeleted = excluded.isDeleted,
                        version = excluded.version,
                        syncState = excluded.syncState
                    """,
                    arguments: [
                        item.id.uuidString,
                        item.memory,
                        item.hash,
                        vectorData,
                        item.userId,
                        item.agentId,
                        item.runId,
                        metadataJson,
                        item.validFrom.timeIntervalSince1970,
                        item.validTo?.timeIntervalSince1970,
                        item.supersededById?.uuidString,
                        item.accessCount,
                        item.lastAccessedAt.timeIntervalSince1970,
                        item.scoreWeight,
                        item.createdAt.timeIntervalSince1970,
                        item.updatedAt.timeIntervalSince1970,
                        item.isDeleted,
                        item.version,
                        "pendingUpload"
                    ]
                )
                
                // Update FTS5 index
                try db.execute(sql: "DELETE FROM memories_fts WHERE id = ?", arguments: [item.id.uuidString])
                if !item.isDeleted {
                    try db.execute(
                        sql: "INSERT INTO memories_fts (id, memory) VALUES (?, ?)",
                        arguments: [item.id.uuidString, item.memory]
                    )
                }
            }
        }
    }

    public func fetch(id: UUID) async throws -> MemoryItem? {
        try await dbQueue.read { db in
            guard let row = try Row.fetchOne(db, sql: "SELECT * FROM memories WHERE id = ?", arguments: [id.uuidString]) else {
                return nil
            }
            return try Self.rowToMemoryItem(row)
        }
    }

    public func fetchAll(filters: MemoryFilter?, limit: Int? = nil, offset: Int? = nil) async throws -> [MemoryItem] {
        try await dbQueue.read { db in
            var sql = "SELECT * FROM memories WHERE 1=1"
            var args: [DatabaseValueConvertible] = []
            
            Self.appendFilterConditions(filters: filters, sql: &sql, args: &args)
            sql += " ORDER BY createdAt DESC"
            
            if let limit = limit {
                sql += " LIMIT \(limit)"
                if let offset = offset {
                    sql += " OFFSET \(offset)"
                }
            }
            
            let rows = try Row.fetchAll(db, sql: sql, arguments: StatementArguments(args))
            return try rows.map { try Self.rowToMemoryItem($0) }
        }
    }

    public func delete(id: UUID) async throws {
        try await dbQueue.write { db in
            let now = Date().timeIntervalSince1970
            try db.execute(
                sql: """
                UPDATE memories
                SET isDeleted = 1, syncState = 'pendingUpload', updatedAt = ?
                WHERE id = ?
                """,
                arguments: [now, id.uuidString]
            )
            try db.execute(sql: "DELETE FROM memories_fts WHERE id = ?", arguments: [id.uuidString])
        }
    }

    public func deleteAll(userId: String?, agentId: String?, runId: String?) async throws {
        try await dbQueue.write { db in
            let now = Date().timeIntervalSince1970
            var sql = "UPDATE memories SET isDeleted = 1, syncState = 'pendingUpload', updatedAt = ? WHERE 1=1"
            var args: [DatabaseValueConvertible] = [now]
            
            if let userId = userId {
                sql += " AND userId = ?"
                args.append(userId)
            }
            if let agentId = agentId {
                sql += " AND agentId = ?"
                args.append(agentId)
            }
            if let runId = runId {
                sql += " AND runId = ?"
                args.append(runId)
            }
            
            try db.execute(sql: sql, arguments: StatementArguments(args))
            try db.execute(sql: "DELETE FROM memories_fts")
        }
    }

    public func reset() async throws {
        try await dbQueue.write { db in
            try db.execute(sql: "DELETE FROM memories")
            try db.execute(sql: "DELETE FROM memories_fts")
            try db.execute(sql: "DELETE FROM memory_history")
            try db.execute(sql: "DELETE FROM core_memory_blocks")
            try db.execute(sql: "DELETE FROM documents")
            try db.execute(sql: "DELETE FROM recall_messages")
            try db.execute(sql: "DELETE FROM conversation_summaries")
        }
    }

    public func search(
        query: String?,
        vector: [Float]?,
        limit: Int,
        filters: MemoryFilter?
    ) async throws -> [SearchResult] {
        let candidates = try await fetchAll(filters: filters)
        guard !candidates.isEmpty else { return [] }
        
        var textScores: [UUID: Float] = [:]
        if let query = query, !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            let ftsResults = try await dbQueue.read { db -> [Row] in
                let sanitizedQuery = query.replacingOccurrences(of: "\"", with: "")
                return try Row.fetchAll(
                    db,
                    sql: """
                    SELECT id, rank FROM memories_fts
                    WHERE memories_fts MATCH ?
                    ORDER BY rank ASC
                    """,
                    arguments: ["\"\(sanitizedQuery)\"*"]
                )
            }
            
            for row in ftsResults {
                if let idString: String = row["id"], let id = UUID(uuidString: idString), let rank: Double = row["rank"] {
                    let normalizedRank = Float(1.0 / (1.0 + abs(rank)))
                    textScores[id] = normalizedRank
                }
            }
        }

        let now = Date().timeIntervalSince1970
        
        var results: [SearchResult] = []
        for item in candidates {
            var vectorSim: Float? = nil
            if let queryVector = vector, !queryVector.isEmpty, !item.vector.isEmpty {
                vectorSim = VectorMath.cosineSimilarity(queryVector, item.vector)
            }
            
            let textRank = textScores[item.id] ?? 0.0
            let vScore = vectorSim ?? 0.0
            
            let ageInDays = Float(max(0, now - item.lastAccessedAt.timeIntervalSince1970) / 86400.0)
            let timeDecay = exp(-decayLambda * ageInDays)
            
            let finalScore = (alpha * vScore + beta * textRank * timeDecay) * item.scoreWeight
            
            if finalScore > 0 || vector == nil {
                results.append(SearchResult(
                    item: item,
                    score: finalScore,
                    vectorSimilarity: vectorSim,
                    textRank: textRank
                ))
            }
        }
        
        results.sort(by: { $0.score > $1.score })
        let trimmedResults = Array(results.prefix(limit))
        
        if !trimmedResults.isEmpty {
            let accessedIds = trimmedResults.map { $0.item.id }
            try await dbQueue.write { db in
                let nowTime = Date().timeIntervalSince1970
                for id in accessedIds {
                    try db.execute(
                        sql: "UPDATE memories SET accessCount = accessCount + 1, lastAccessedAt = ? WHERE id = ?",
                        arguments: [nowTime, id.uuidString]
                    )
                }
            }
        }
        
        return trimmedResults
    }

    // MARK: - Documents & Bookmarks (Supermemory)

    public func saveDocument(doc: DocumentItem) async throws {
        try await dbQueue.write { db in
            let vectorData = Data(bytes: doc.vector, count: doc.vector.count * MemoryLayout<Float>.size)
            let tagsData = try JSONEncoder().encode(doc.tags)
            let tagsJson = String(data: tagsData, encoding: .utf8) ?? "[]"
            let metadataData = try JSONEncoder().encode(doc.metadata)
            let metadataJson = String(data: metadataData, encoding: .utf8) ?? "{}"

            try db.execute(
                sql: """
                INSERT INTO documents (
                    id, title, url, content, chunkIndex, totalChunks, vectorData,
                    tagsJson, userId, metadataJson, createdAt, updatedAt, isDeleted
                ) VALUES (
                    ?, ?, ?, ?, ?, ?, ?,
                    ?, ?, ?, ?, ?, ?
                ) ON CONFLICT(id) DO UPDATE SET
                    title = excluded.title,
                    url = excluded.url,
                    content = excluded.content,
                    vectorData = excluded.vectorData,
                    tagsJson = excluded.tagsJson,
                    metadataJson = excluded.metadataJson,
                    updatedAt = excluded.updatedAt,
                    isDeleted = excluded.isDeleted
                """,
                arguments: [
                    doc.id.uuidString,
                    doc.title,
                    doc.url,
                    doc.content,
                    doc.chunkIndex,
                    doc.totalChunks,
                    vectorData,
                    tagsJson,
                    doc.userId,
                    metadataJson,
                    doc.createdAt.timeIntervalSince1970,
                    doc.updatedAt.timeIntervalSince1970,
                    doc.isDeleted
                ]
            )
        }
    }

    public func searchDocuments(query: String?, vector: [Float]?, limit: Int, userId: String?) async throws -> [DocumentItem] {
        try await dbQueue.read { db in
            var sql = "SELECT * FROM documents WHERE isDeleted = 0"
            var args: [DatabaseValueConvertible] = []
            if let userId = userId {
                sql += " AND (userId = ? OR userId IS NULL)"
                args.append(userId)
            }
            
            let rows = try Row.fetchAll(db, sql: sql, arguments: StatementArguments(args))
            var docs: [DocumentItem] = []
            for row in rows {
                var docVector: [Float] = []
                if let vectorBlob: Data = row["vectorData"] {
                    docVector = vectorBlob.withUnsafeBytes { buffer in
                        Array(buffer.bindMemory(to: Float.self))
                    }
                }
                
                var tags: [String] = []
                if let tagsJson: String = row["tagsJson"], let data = tagsJson.data(using: .utf8) {
                    tags = (try? JSONDecoder().decode([String].self, from: data)) ?? []
                }

                let item = DocumentItem(
                    id: UUID(uuidString: row["id"]) ?? UUID(),
                    title: row["title"],
                    url: row["url"],
                    content: row["content"],
                    chunkIndex: row["chunkIndex"],
                    totalChunks: row["totalChunks"],
                    vector: docVector,
                    tags: tags,
                    userId: row["userId"],
                    metadata: [:],
                    createdAt: Date(timeIntervalSince1970: row["createdAt"]),
                    updatedAt: Date(timeIntervalSince1970: row["updatedAt"]),
                    isDeleted: row["isDeleted"]
                )
                docs.append(item)
            }

            if let queryVector = vector, !queryVector.isEmpty {
                docs.sort { doc1, doc2 in
                    let sim1 = VectorMath.cosineSimilarity(queryVector, doc1.vector)
                    let sim2 = VectorMath.cosineSimilarity(queryVector, doc2.vector)
                    return sim1 > sim2
                }
            }

            return Array(docs.prefix(limit))
        }
    }

    // MARK: - Recall Memory (Letta/MemGPT)

    public func logRecallMessage(message: RecallMessage) async throws {
        try await dbQueue.write { db in
            try db.execute(
                sql: """
                INSERT INTO recall_messages (id, role, content, userId, agentId, runId, timestamp)
                VALUES (?, ?, ?, ?, ?, ?, ?)
                """,
                arguments: [
                    message.id.uuidString,
                    message.role.rawValue,
                    message.content,
                    message.userId,
                    message.agentId,
                    message.runId,
                    message.timestamp.timeIntervalSince1970
                ]
            )
        }
    }

    public func fetchRecallMessages(userId: String?, agentId: String?, runId: String?, limit: Int? = nil) async throws -> [RecallMessage] {
        try await dbQueue.read { db in
            var sql = "SELECT * FROM recall_messages WHERE 1=1"
            var args: [DatabaseValueConvertible] = []
            
            if let userId = userId {
                sql += " AND userId = ?"
                args.append(userId)
            }
            if let agentId = agentId {
                sql += " AND agentId = ?"
                args.append(agentId)
            }
            if let runId = runId {
                sql += " AND runId = ?"
                args.append(runId)
            }
            
            sql += " ORDER BY timestamp ASC"
            if let limit = limit {
                sql += " LIMIT \(limit)"
            }

            let rows = try Row.fetchAll(db, sql: sql, arguments: StatementArguments(args))
            return rows.compactMap { row -> RecallMessage? in
                guard let idStr: String = row["id"],
                      let id = UUID(uuidString: idStr),
                      let roleStr: String = row["role"],
                      let role = Message.Role(rawValue: roleStr),
                      let content: String = row["content"],
                      let tsDouble: Double = row["timestamp"]
                else { return nil }

                return RecallMessage(
                    id: id,
                    role: role,
                    content: content,
                    userId: row["userId"],
                    agentId: row["agentId"],
                    runId: row["runId"],
                    timestamp: Date(timeIntervalSince1970: tsDouble)
                )
            }
        }
    }

    // MARK: - Conversation Summaries (Zep)

    public func saveSummary(summary: ConversationSummary) async throws {
        try await dbQueue.write { db in
            try db.execute(
                sql: """
                INSERT INTO conversation_summaries (id, userId, agentId, runId, summary, messageCount, lastMessageTimestamp, createdAt, updatedAt)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
                ON CONFLICT(id) DO UPDATE SET
                    summary = excluded.summary,
                    messageCount = excluded.messageCount,
                    lastMessageTimestamp = excluded.lastMessageTimestamp,
                    updatedAt = excluded.updatedAt
                """,
                arguments: [
                    summary.id.uuidString,
                    summary.userId,
                    summary.agentId,
                    summary.runId,
                    summary.summary,
                    summary.messageCount,
                    summary.lastMessageTimestamp.timeIntervalSince1970,
                    summary.createdAt.timeIntervalSince1970,
                    summary.updatedAt.timeIntervalSince1970
                ]
            )
        }
    }

    public func fetchSummary(userId: String?, agentId: String?, runId: String?) async throws -> ConversationSummary? {
        try await dbQueue.read { db in
            var sql = "SELECT * FROM conversation_summaries WHERE 1=1"
            var args: [DatabaseValueConvertible] = []
            
            if let userId = userId {
                sql += " AND userId = ?"
                args.append(userId)
            }
            if let agentId = agentId {
                sql += " AND agentId = ?"
                args.append(agentId)
            }
            if let runId = runId {
                sql += " AND runId = ?"
                args.append(runId)
            }
            sql += " ORDER BY updatedAt DESC LIMIT 1"

            guard let row = try Row.fetchOne(db, sql: sql, arguments: StatementArguments(args)) else {
                return nil
            }

            return ConversationSummary(
                id: UUID(uuidString: row["id"]) ?? UUID(),
                userId: row["userId"],
                agentId: row["agentId"],
                runId: row["runId"],
                summary: row["summary"],
                messageCount: row["messageCount"],
                lastMessageTimestamp: Date(timeIntervalSince1970: row["lastMessageTimestamp"]),
                createdAt: Date(timeIntervalSince1970: row["createdAt"]),
                updatedAt: Date(timeIntervalSince1970: row["updatedAt"])
            )
        }
    }

    // MARK: - History / Auditing

    public func logHistory(item: MemoryHistoryItem) async throws {
        try await dbQueue.write { db in
            try db.execute(
                sql: """
                INSERT INTO memory_history (id, memoryId, action, oldMemory, newMemory, timestamp, userId)
                VALUES (?, ?, ?, ?, ?, ?, ?)
                """,
                arguments: [
                    item.id.uuidString,
                    item.memoryId.uuidString,
                    item.action.rawValue,
                    item.oldMemory,
                    item.newMemory,
                    item.timestamp.timeIntervalSince1970,
                    item.userId
                ]
            )
        }
    }

    public func fetchHistory(memoryId: UUID?, userId: String?) async throws -> [MemoryHistoryItem] {
        try await dbQueue.read { db in
            var sql = "SELECT * FROM memory_history WHERE 1=1"
            var args: [DatabaseValueConvertible] = []
            
            if let memoryId = memoryId {
                sql += " AND memoryId = ?"
                args.append(memoryId.uuidString)
            }
            if let userId = userId {
                sql += " AND userId = ?"
                args.append(userId)
            }
            
            sql += " ORDER BY timestamp DESC"
            
            let rows = try Row.fetchAll(db, sql: sql, arguments: StatementArguments(args))
            return rows.compactMap { row -> MemoryHistoryItem? in
                guard let idStr: String = row["id"],
                      let id = UUID(uuidString: idStr),
                      let memIdStr: String = row["memoryId"],
                      let memoryId = UUID(uuidString: memIdStr),
                      let actionStr: String = row["action"],
                      let action = MemoryAction(rawValue: actionStr),
                      let timestampDouble: Double = row["timestamp"]
                else { return nil }
                
                return MemoryHistoryItem(
                    id: id,
                    memoryId: memoryId,
                    action: action,
                    oldMemory: row["oldMemory"],
                    newMemory: row["newMemory"],
                    timestamp: Date(timeIntervalSince1970: timestampDouble),
                    userId: row["userId"]
                )
            }
        }
    }

    // MARK: - CloudKit Sync Operations

    public func fetchPendingSyncItems() async throws -> [MemoryItem] {
        try await dbQueue.read { db in
            let rows = try Row.fetchAll(db, sql: "SELECT * FROM memories WHERE syncState = 'pendingUpload'")
            return try rows.map { try Self.rowToMemoryItem($0) }
        }
    }

    public func markSynced(ids: [UUID]) async throws {
        try await dbQueue.write { db in
            for id in ids {
                try db.execute(
                    sql: "UPDATE memories SET syncState = 'synced' WHERE id = ?",
                    arguments: [id.uuidString]
                )
            }
        }
    }

    // MARK: - Core Working Memory Blocks

    public func getCoreMemoryBlock() async throws -> [String: String] {
        try await dbQueue.read { db in
            let rows = try Row.fetchAll(db, sql: "SELECT blockKey, blockValue FROM core_memory_blocks")
            var dict: [String: String] = [:]
            for row in rows {
                if let k: String = row["blockKey"], let v: String = row["blockValue"] {
                    dict[k] = v
                }
            }
            return dict
        }
    }

    public func setCoreMemoryBlock(key: String, value: String) async throws {
        try await dbQueue.write { db in
            let now = Date().timeIntervalSince1970
            try db.execute(
                sql: """
                INSERT INTO core_memory_blocks (blockKey, blockValue, updatedAt)
                VALUES (?, ?, ?)
                ON CONFLICT(blockKey) DO UPDATE SET blockValue = excluded.blockValue, updatedAt = excluded.updatedAt
                """,
                arguments: [key, value, now]
            )
        }
    }

    // MARK: - Helper Methods

    private static func rowToMemoryItem(_ row: Row) throws -> MemoryItem {
        let idStr: String = row["id"]
        let id = UUID(uuidString: idStr) ?? UUID()
        let memory: String = row["memory"]
        let hash: String = row["hash"]
        
        var vector: [Float] = []
        if let vectorBlob: Data = row["vectorData"] {
            vector = vectorBlob.withUnsafeBytes { buffer in
                Array(buffer.bindMemory(to: Float.self))
            }
        }
        
        var metadata: [String: String] = [:]
        if let jsonStr: String = row["metadataJson"], let data = jsonStr.data(using: .utf8) {
            metadata = (try? JSONDecoder().decode([String: String].self, from: data)) ?? [:]
        }
        
        let validFromDouble: Double = row["validFrom"]
        let validToDouble: Double? = row["validTo"]
        let supersededStr: String? = row["supersededById"]
        
        return MemoryItem(
            id: id,
            memory: memory,
            hash: hash,
            vector: vector,
            userId: row["userId"],
            agentId: row["agentId"],
            runId: row["runId"],
            metadata: metadata,
            validFrom: Date(timeIntervalSince1970: validFromDouble),
            validTo: validToDouble != nil ? Date(timeIntervalSince1970: validToDouble!) : nil,
            supersededById: supersededStr != nil ? UUID(uuidString: supersededStr!) : nil,
            accessCount: row["accessCount"],
            lastAccessedAt: Date(timeIntervalSince1970: row["lastAccessedAt"]),
            scoreWeight: Float(row["scoreWeight"] as Double),
            createdAt: Date(timeIntervalSince1970: row["createdAt"]),
            updatedAt: Date(timeIntervalSince1970: row["updatedAt"]),
            isDeleted: row["isDeleted"],
            version: Int64(row["version"] as Int)
        )
    }

    private static func appendFilterConditions(filters: MemoryFilter?, sql: inout String, args: inout [DatabaseValueConvertible]) {
        guard let filters = filters else {
            sql += " AND isDeleted = 0"
            return
        }
        
        if !filters.includeDeleted {
            sql += " AND isDeleted = 0"
        }
        if let userId = filters.userId {
            sql += " AND userId = ?"
            args.append(userId)
        }
        if let agentId = filters.agentId {
            sql += " AND agentId = ?"
            args.append(agentId)
        }
        if let runId = filters.runId {
            sql += " AND runId = ?"
            args.append(runId)
        }
        if let activeAt = filters.activeAt {
            let activeDouble = activeAt.timeIntervalSince1970
            sql += " AND validFrom <= ? AND (validTo IS NULL OR validTo > ?)"
            args.append(activeDouble)
            args.append(activeDouble)
        }
    }
}
