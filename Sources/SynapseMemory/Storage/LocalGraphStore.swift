import Foundation
import GRDB

/// Local SQLite-backed implementation of the Knowledge Graph storage engine.
public actor LocalGraphStore: GraphStore {
    private let dbQueue: DatabaseQueue

    public init(databasePath: String? = nil) throws {
        let path: String
        if let databasePath = databasePath {
            path = databasePath
        } else {
            let fileManager = FileManager.default
            let urls = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)
            let appSupportDir = urls.first ?? fileManager.temporaryDirectory
            let synapseDir = appSupportDir.appendingPathComponent("SynapseMemory", isDirectory: true)
            try fileManager.createDirectory(at: synapseDir, withIntermediateDirectories: true)
            path = synapseDir.appendingPathComponent("synapse_graph.sqlite").path
        }
        
        self.dbQueue = try DatabaseQueue(path: path)
        try Self.setupSchema(dbQueue: dbQueue)
    }

    /// In-memory graph database initializer for testing.
    public init(inMemory: Bool) throws {
        self.dbQueue = try DatabaseQueue()
        try Self.setupSchema(dbQueue: dbQueue)
    }

    private static func setupSchema(dbQueue: DatabaseQueue) throws {
        var migrator = DatabaseMigrator()
        
        migrator.registerMigration("v1_create_graph_tables") { db in
            // Entities table
            try db.create(table: "graph_entities") { t in
                t.column("id", .text).primaryKey()
                t.column("name", .text).notNull()
                t.column("type", .text).notNull()
                t.column("userId", .text)
                t.column("agentId", .text)
                t.column("runId", .text)
                t.column("metadataJson", .text)
                t.column("createdAt", .double).notNull()
                t.column("updatedAt", .double).notNull()
                t.column("isDeleted", .boolean).notNull().defaults(to: false)
                t.column("version", .integer).notNull().defaults(to: 1)
                t.column("syncState", .text).notNull().defaults(to: "pendingUpload")
            }
            
            // Relations table
            try db.create(table: "graph_relations") { t in
                t.column("id", .text).primaryKey()
                t.column("sourceEntityId", .text).notNull()
                t.column("targetEntityId", .text).notNull()
                t.column("relationshipType", .text).notNull()
                t.column("userId", .text)
                t.column("metadataJson", .text)
                t.column("weight", .double).notNull().defaults(to: 1.0)
                t.column("createdAt", .double).notNull()
                t.column("updatedAt", .double).notNull()
                t.column("isDeleted", .boolean).notNull().defaults(to: false)
                t.column("version", .integer).notNull().defaults(to: 1)
                t.column("syncState", .text).notNull().defaults(to: "pendingUpload")
            }
        }
        
        try migrator.migrate(dbQueue)
    }

    // MARK: - GraphStore Implementation

    public func saveEntity(_ entity: Entity) async throws {
        try await dbQueue.write { db in
            let metadataData = try JSONEncoder().encode(entity.metadata)
            let metadataJson = String(data: metadataData, encoding: .utf8) ?? "{}"

            try db.execute(
                sql: """
                INSERT INTO graph_entities (
                    id, name, type, userId, agentId, runId, metadataJson,
                    createdAt, updatedAt, isDeleted, version, syncState
                ) VALUES (
                    ?, ?, ?, ?, ?, ?, ?,
                    ?, ?, ?, ?, ?
                ) ON CONFLICT(id) DO UPDATE SET
                    name = excluded.name,
                    type = excluded.type,
                    userId = excluded.userId,
                    agentId = excluded.agentId,
                    runId = excluded.runId,
                    metadataJson = excluded.metadataJson,
                    updatedAt = excluded.updatedAt,
                    isDeleted = excluded.isDeleted,
                    version = excluded.version,
                    syncState = excluded.syncState
                """,
                arguments: [
                    entity.id.uuidString,
                    entity.name,
                    entity.type,
                    entity.userId,
                    entity.agentId,
                    entity.runId,
                    metadataJson,
                    entity.createdAt.timeIntervalSince1970,
                    entity.updatedAt.timeIntervalSince1970,
                    entity.isDeleted,
                    entity.version,
                    "pendingUpload"
                ]
            )
        }
    }

    public func fetchEntity(name: String, userId: String?) async throws -> Entity? {
        try await dbQueue.read { db in
            var sql = "SELECT * FROM graph_entities WHERE LOWER(name) = LOWER(?) AND isDeleted = 0"
            var args: [DatabaseValueConvertible] = [name]
            
            if let userId = userId {
                sql += " AND (userId = ? OR userId IS NULL)"
                args.append(userId)
            }
            
            guard let row = try Row.fetchOne(db, sql: sql, arguments: StatementArguments(args)) else {
                return nil
            }
            return try Self.rowToEntity(row)
        }
    }

    public func fetchEntities(userId: String?) async throws -> [Entity] {
        try await dbQueue.read { db in
            var sql = "SELECT * FROM graph_entities WHERE isDeleted = 0"
            var args: [DatabaseValueConvertible] = []
            
            if let userId = userId {
                sql += " AND userId = ?"
                args.append(userId)
            }
            
            let rows = try Row.fetchAll(db, sql: sql, arguments: StatementArguments(args))
            return try rows.map { try Self.rowToEntity($0) }
        }
    }

    public func saveRelation(_ relation: Relation) async throws {
        try await dbQueue.write { db in
            let metadataData = try JSONEncoder().encode(relation.metadata)
            let metadataJson = String(data: metadataData, encoding: .utf8) ?? "{}"

            try db.execute(
                sql: """
                INSERT INTO graph_relations (
                    id, sourceEntityId, targetEntityId, relationshipType, userId,
                    metadataJson, weight, createdAt, updatedAt, isDeleted, version, syncState
                ) VALUES (
                    ?, ?, ?, ?, ?,
                    ?, ?, ?, ?, ?, ?, ?
                ) ON CONFLICT(id) DO UPDATE SET
                    relationshipType = excluded.relationshipType,
                    metadataJson = excluded.metadataJson,
                    weight = excluded.weight,
                    updatedAt = excluded.updatedAt,
                    isDeleted = excluded.isDeleted,
                    version = excluded.version,
                    syncState = excluded.syncState
                """,
                arguments: [
                    relation.id.uuidString,
                    relation.sourceEntityId.uuidString,
                    relation.targetEntityId.uuidString,
                    relation.relationshipType,
                    relation.userId,
                    metadataJson,
                    relation.weight,
                    relation.createdAt.timeIntervalSince1970,
                    relation.updatedAt.timeIntervalSince1970,
                    relation.isDeleted,
                    relation.version,
                    "pendingUpload"
                ]
            )
        }
    }

    public func fetchRelations(from sourceEntityId: UUID) async throws -> [(relation: Relation, target: Entity)] {
        try await dbQueue.read { db in
            let sql = """
            SELECT r.*, e.id as e_id, e.name as e_name, e.type as e_type, e.userId as e_userId,
                   e.metadataJson as e_metadataJson, e.createdAt as e_createdAt,
                   e.updatedAt as e_updatedAt, e.isDeleted as e_isDeleted, e.version as e_version
            FROM graph_relations r
            JOIN graph_entities e ON r.targetEntityId = e.id
            WHERE r.sourceEntityId = ? AND r.isDeleted = 0 AND e.isDeleted = 0
            """
            let rows = try Row.fetchAll(db, sql: sql, arguments: [sourceEntityId.uuidString])
            
            var results: [(relation: Relation, target: Entity)] = []
            for row in rows {
                let relation = try Self.rowToRelation(row)
                let targetEntity = Entity(
                    id: UUID(uuidString: row["e_id"]) ?? UUID(),
                    name: row["e_name"],
                    type: row["e_type"],
                    userId: row["e_userId"],
                    metadata: Self.parseMetadata(row["e_metadataJson"]),
                    createdAt: Date(timeIntervalSince1970: row["e_createdAt"]),
                    updatedAt: Date(timeIntervalSince1970: row["e_updatedAt"]),
                    isDeleted: row["e_isDeleted"],
                    version: Int64(row["e_version"] as Int)
                )
                results.append((relation, targetEntity))
            }
            return results
        }
    }

    public func fetchTriples(userId: String?) async throws -> [GraphTriple] {
        try await dbQueue.read { db in
            var sql = """
            SELECT s.name as s_name, s.type as s_type, r.relationshipType as r_type,
                   t.name as t_name, t.type as t_type
            FROM graph_relations r
            JOIN graph_entities s ON r.sourceEntityId = s.id
            JOIN graph_entities t ON r.targetEntityId = t.id
            WHERE r.isDeleted = 0 AND s.isDeleted = 0 AND t.isDeleted = 0
            """
            var args: [DatabaseValueConvertible] = []
            if let userId = userId {
                sql += " AND r.userId = ?"
                args.append(userId)
            }
            
            let rows = try Row.fetchAll(db, sql: sql, arguments: StatementArguments(args))
            return rows.map { row in
                GraphTriple(
                    sourceEntityName: row["s_name"],
                    sourceEntityType: row["s_type"],
                    relationshipType: row["r_type"],
                    targetEntityName: row["t_name"],
                    targetEntityType: row["t_type"]
                )
            }
        }
    }

    public func deleteEntity(id: UUID) async throws {
        try await dbQueue.write { db in
            let now = Date().timeIntervalSince1970
            try db.execute(
                sql: "UPDATE graph_entities SET isDeleted = 1, syncState = 'pendingUpload', updatedAt = ? WHERE id = ?",
                arguments: [now, id.uuidString]
            )
            try db.execute(
                sql: """
                UPDATE graph_relations
                SET isDeleted = 1, syncState = 'pendingUpload', updatedAt = ?
                WHERE sourceEntityId = ? OR targetEntityId = ?
                """,
                arguments: [now, id.uuidString, id.uuidString]
            )
        }
    }

    public func deleteAll(userId: String?, agentId: String?, runId: String?) async throws {
        try await dbQueue.write { db in
            let now = Date().timeIntervalSince1970
            var entitySql = "UPDATE graph_entities SET isDeleted = 1, syncState = 'pendingUpload', updatedAt = ? WHERE 1=1"
            var relationSql = "UPDATE graph_relations SET isDeleted = 1, syncState = 'pendingUpload', updatedAt = ? WHERE 1=1"
            var args: [DatabaseValueConvertible] = [now]
            
            if let userId = userId {
                entitySql += " AND userId = ?"
                relationSql += " AND userId = ?"
                args.append(userId)
            }
            if let agentId = agentId {
                entitySql += " AND agentId = ?"
                args.append(agentId)
            }
            if let runId = runId {
                entitySql += " AND runId = ?"
                args.append(runId)
            }
            
            try db.execute(sql: entitySql, arguments: StatementArguments(args))
            try db.execute(sql: relationSql, arguments: StatementArguments(args))
        }
    }

    public func fetchPendingSyncGraph() async throws -> (entities: [Entity], relations: [Relation]) {
        try await dbQueue.read { db in
            let entityRows = try Row.fetchAll(db, sql: "SELECT * FROM graph_entities WHERE syncState = 'pendingUpload'")
            let entities = try entityRows.map { try Self.rowToEntity($0) }
            
            let relationRows = try Row.fetchAll(db, sql: "SELECT * FROM graph_relations WHERE syncState = 'pendingUpload'")
            let relations = try relationRows.map { try Self.rowToRelation($0) }
            
            return (entities, relations)
        }
    }

    public func markGraphSynced(entityIds: [UUID], relationIds: [UUID]) async throws {
        try await dbQueue.write { db in
            for id in entityIds {
                try db.execute(sql: "UPDATE graph_entities SET syncState = 'synced' WHERE id = ?", arguments: [id.uuidString])
            }
            for id in relationIds {
                try db.execute(sql: "UPDATE graph_relations SET syncState = 'synced' WHERE id = ?", arguments: [id.uuidString])
            }
        }
    }

    // MARK: - Helper Methods

    private static func rowToEntity(_ row: Row) throws -> Entity {
        let idStr: String = row["id"]
        let id = UUID(uuidString: idStr) ?? UUID()
        let name: String = row["name"]
        let type: String = row["type"]
        
        let metadata = parseMetadata(row["metadataJson"])
        let createdAtDouble: Double = row["createdAt"]
        let updatedAtDouble: Double = row["updatedAt"]
        
        return Entity(
            id: id,
            name: name,
            type: type,
            userId: row["userId"],
            agentId: row["agentId"],
            runId: row["runId"],
            metadata: metadata,
            createdAt: Date(timeIntervalSince1970: createdAtDouble),
            updatedAt: Date(timeIntervalSince1970: updatedAtDouble),
            isDeleted: row["isDeleted"],
            version: Int64(row["version"] as Int)
        )
    }

    private static func rowToRelation(_ row: Row) throws -> Relation {
        let idStr: String = row["id"]
        let id = UUID(uuidString: idStr) ?? UUID()
        let sourceIdStr: String = row["sourceEntityId"]
        let targetIdStr: String = row["targetEntityId"]
        let relType: String = row["relationshipType"]
        
        let metadata = parseMetadata(row["metadataJson"])
        let createdAtDouble: Double = row["createdAt"]
        let updatedAtDouble: Double = row["updatedAt"]
        let weightDouble: Double = row["weight"]
        
        return Relation(
            id: id,
            sourceEntityId: UUID(uuidString: sourceIdStr) ?? UUID(),
            targetEntityId: UUID(uuidString: targetIdStr) ?? UUID(),
            relationshipType: relType,
            userId: row["userId"],
            metadata: metadata,
            weight: Float(weightDouble),
            createdAt: Date(timeIntervalSince1970: createdAtDouble),
            updatedAt: Date(timeIntervalSince1970: updatedAtDouble),
            isDeleted: row["isDeleted"],
            version: Int64(row["version"] as Int)
        )
    }

    private static func parseMetadata(_ jsonStr: String?) -> [String: String] {
        guard let jsonStr = jsonStr, let data = jsonStr.data(using: .utf8) else { return [:] }
        return (try? JSONDecoder().decode([String: String].self, from: data)) ?? [:]
    }
}
