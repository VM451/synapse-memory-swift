import Foundation
import OSLog

/// Primary entry point for Mem0Swift library. Manages local vector storage, Knowledge Graph extraction,
/// Spotlight search indexing, working memory blocks, and CloudKit background sync.
public actor Mem0Client: CoreMemoryManager, MemoryAgentTool {
    /// Global shared client reference for AppIntents / Siri integration.
    nonisolated(unsafe) public static var shared: Mem0Client?

    public let config: Mem0Config
    public let vectorStore: VectorStore
    public let graphStore: GraphStore
    public let extractor: MemoryExtractor
    public let syncEngine: CloudKitSyncEngine?
    public let spotlightIndexer: CoreSpotlightIndexer

    private let logger = Logger(subsystem: "com.mem0.swift", category: "Mem0Client")

    public init(config: Mem0Config = Mem0Config()) async throws {
        self.config = config
        
        if let store = config.customVectorStore {
            self.vectorStore = store
        } else {
            self.vectorStore = try LocalVectorStore(databasePath: config.databasePath)
        }
        
        if let gStore = config.customGraphStore {
            self.graphStore = gStore
        } else {
            self.graphStore = try LocalGraphStore()
        }
        
        self.extractor = MemoryExtractor(
            vectorStore: vectorStore,
            graphStore: graphStore,
            embeddingProvider: config.embeddingProvider,
            llmProvider: config.llmProvider,
            customExtractionPrompt: config.customExtractionPrompt
        )

        if config.enableAutoSync {
            let engine = CloudKitSyncEngine(containerId: config.cloudKitContainerId)
            self.syncEngine = engine
            Task {
                try? await engine.setupZoneAndSubscriptions()
            }
        } else {
            self.syncEngine = nil
        }
        
        self.spotlightIndexer = CoreSpotlightIndexer.shared
        
        Self.shared = self
    }

    // MARK: - Public Client APIs

    /// Extracts and adds/updates memories and knowledge graph relations from conversation turns.
    @discardableResult
    public func add(
        messages: [Message],
        userId: String? = nil,
        agentId: String? = nil,
        runId: String? = nil,
        metadata: [String: String] = [:]
    ) async throws -> MemoryChangeset {
        let changeset = try await extractor.extractAndApply(
            messages: messages,
            userId: userId,
            agentId: agentId,
            runId: runId,
            metadata: metadata
        )

        let affected = changeset.affectedItems
        if config.enableSpotlightIndexing, !affected.isEmpty {
            let indexer = spotlightIndexer
            Task {
                try? await indexer.index(memories: affected)
            }
        }

        if config.enableAutoSync, let syncEngine = syncEngine, !affected.isEmpty {
            Task {
                try? await syncEngine.upload(memories: affected)
            }
        }

        return changeset
    }

    /// Directly saves a single textual memory statement.
    @discardableResult
    public func add(
        memory: String,
        userId: String? = nil,
        agentId: String? = nil,
        runId: String? = nil,
        metadata: [String: String] = [:]
    ) async throws -> MemoryItem {
        let vector = try await config.embeddingProvider.embed(text: memory)
        let item = MemoryItem(
            memory: memory,
            vector: vector,
            userId: userId,
            agentId: agentId,
            runId: runId,
            metadata: metadata
        )

        try await vectorStore.save(item: item)
        try await vectorStore.logHistory(item: MemoryHistoryItem(
            memoryId: item.id,
            action: .add,
            newMemory: item.memory,
            userId: userId
        ))

        let items = [item]
        if config.enableSpotlightIndexing {
            let indexer = spotlightIndexer
            Task {
                try? await indexer.index(memories: items)
            }
        }

        if config.enableAutoSync, let syncEngine = syncEngine {
            Task {
                try? await syncEngine.upload(memories: items)
            }
        }

        return item
    }

    /// Directly saves multiple raw memory statements in batch.
    @discardableResult
    public func batchAdd(
        memories: [String],
        userId: String? = nil,
        agentId: String? = nil,
        runId: String? = nil,
        metadata: [String: String] = [:]
    ) async throws -> [MemoryItem] {
        var items: [MemoryItem] = []
        for text in memories {
            let vector = try await config.embeddingProvider.embed(text: text)
            let item = MemoryItem(
                memory: text,
                vector: vector,
                userId: userId,
                agentId: agentId,
                runId: runId,
                metadata: metadata
            )
            items.append(item)
        }

        try await vectorStore.saveBatch(items: items)
        
        let batchItems = items
        if config.enableSpotlightIndexing, !batchItems.isEmpty {
            let indexer = spotlightIndexer
            Task {
                try? await indexer.index(memories: batchItems)
            }
        }

        if config.enableAutoSync, let syncEngine = syncEngine, !batchItems.isEmpty {
            Task {
                try? await syncEngine.upload(memories: batchItems)
            }
        }

        return items
    }

    /// Searches relevant memories using vector similarity and BM25 text rank fusion.
    public func search(
        query: String,
        userId: String? = nil,
        agentId: String? = nil,
        runId: String? = nil,
        limit: Int = 5
    ) async throws -> [SearchResult] {
        let vector = try await config.embeddingProvider.embed(text: query)
        let filter = MemoryFilter(userId: userId, agentId: agentId, runId: runId)
        return try await vectorStore.search(query: query, vector: vector, limit: limit, filters: filter)
    }

    /// Fetch a memory by its UUID.
    public func get(id: UUID) async throws -> MemoryItem? {
        return try await vectorStore.fetch(id: id)
    }

    /// Fetch all memories matching optional filters, with optional pagination.
    public func getAll(
        userId: String? = nil,
        agentId: String? = nil,
        runId: String? = nil,
        limit: Int? = nil,
        offset: Int? = nil
    ) async throws -> [MemoryItem] {
        let filter = MemoryFilter(userId: userId, agentId: agentId, runId: runId)
        return try await vectorStore.fetchAll(filters: filter, limit: limit, offset: offset)
    }

    /// Update an existing memory item.
    @discardableResult
    public func update(id: UUID, memory: String) async throws -> MemoryItem {
        guard var existing = try await vectorStore.fetch(id: id) else {
            throw NSError(domain: "Mem0Swift", code: 404, userInfo: [NSLocalizedDescriptionKey: "Memory not found"])
        }

        let oldText = existing.memory
        let newVector = try await config.embeddingProvider.embed(text: memory)

        existing.memory = memory
        existing.hash = MemoryItem.computeHash(for: memory)
        existing.vector = newVector
        existing.updatedAt = Date()
        existing.version += 1

        try await vectorStore.save(item: existing)
        try await vectorStore.logHistory(item: MemoryHistoryItem(
            memoryId: existing.id,
            action: .update,
            oldMemory: oldText,
            newMemory: memory,
            userId: existing.userId
        ))

        let updatedItems = [existing]
        if config.enableSpotlightIndexing {
            let indexer = spotlightIndexer
            Task {
                try? await indexer.index(memories: updatedItems)
            }
        }

        if config.enableAutoSync, let syncEngine = syncEngine {
            Task {
                try? await syncEngine.upload(memories: updatedItems)
            }
        }

        return existing
    }

    /// Delete a single memory item.
    public func delete(id: UUID) async throws {
        guard let existing = try await vectorStore.fetch(id: id) else { return }
        
        try await vectorStore.delete(id: id)
        try await vectorStore.logHistory(item: MemoryHistoryItem(
            memoryId: id,
            action: .delete,
            oldMemory: existing.memory,
            userId: existing.userId
        ))

        let deleteId = id
        if config.enableSpotlightIndexing {
            let indexer = spotlightIndexer
            Task {
                try? await indexer.deindex(ids: [deleteId])
            }
        }
    }

    /// Bulk delete all memories matching a specific user, agent, or run session.
    public func deleteAll(userId: String? = nil, agentId: String? = nil, runId: String? = nil) async throws {
        try await vectorStore.deleteAll(userId: userId, agentId: agentId, runId: runId)
        try await graphStore.deleteAll(userId: userId, agentId: agentId, runId: runId)
    }

    /// Completely wipe all stored memories, history logs, and working blocks.
    public func reset() async throws {
        try await vectorStore.reset()
        try await graphStore.deleteAll(userId: nil, agentId: nil, runId: nil)
    }

    /// Retrieve audit history logs.
    public func history(memoryId: UUID? = nil, userId: String? = nil) async throws -> [MemoryHistoryItem] {
        return try await vectorStore.fetchHistory(memoryId: memoryId, userId: userId)
    }

    // MARK: - Knowledge Graph APIs

    /// Retrieve all knowledge graph entities for a user.
    public func getEntities(userId: String? = nil) async throws -> [Entity] {
        return try await graphStore.fetchEntities(userId: userId)
    }

    /// Retrieve all knowledge graph relational triples for a user.
    public func getRelations(userId: String? = nil) async throws -> [GraphTriple] {
        return try await graphStore.fetchTriples(userId: userId)
    }

    /// Trigger bi-directional CloudKit delta sync pass manually.
    public func sync() async throws {
        guard let syncEngine = syncEngine else { return }
        
        // 1. Upload pending local vector memories
        let pendingUploads = try await vectorStore.fetchPendingSyncItems()
        if !pendingUploads.isEmpty {
            try await syncEngine.upload(memories: pendingUploads)
            try await vectorStore.markSynced(ids: pendingUploads.map { $0.id })
        }

        // 2. Upload pending knowledge graph entities & relations
        let (pendingEntities, pendingRelations) = try await graphStore.fetchPendingSyncGraph()
        if !pendingEntities.isEmpty || !pendingRelations.isEmpty {
            try await syncEngine.uploadGraph(entities: pendingEntities, relations: pendingRelations)
            try await graphStore.markGraphSynced(
                entityIds: pendingEntities.map { $0.id },
                relationIds: pendingRelations.map { $0.id }
            )
        }
    }

    // MARK: - CoreMemoryManager & MemoryAgentTool Protocol Compliance

    public var coreBlock: [String: String] {
        get async throws {
            if let localStore = vectorStore as? LocalVectorStore {
                return try await localStore.getCoreMemoryBlock()
            }
            return [:]
        }
    }

    public func updateCoreBlock(key: String, value: String) async throws {
        if let localStore = vectorStore as? LocalVectorStore {
            try await localStore.setCoreMemoryBlock(key: key, value: value)
        }
    }

    public func searchMemory(query: String) async throws -> String {
        let results = try await search(query: query, limit: 5)
        return results.map { "- \($0.item.memory)" }.joined(separator: "\n")
    }
}
