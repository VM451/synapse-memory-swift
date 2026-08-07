import Foundation

/// Comprehensive storage interface for storing, searching, and managing memories, documents, and dialogue recall.
public protocol VectorStore: Sendable {
    // MARK: - Core Memories
    func save(item: MemoryItem) async throws
    func saveBatch(items: [MemoryItem]) async throws
    func search(
        query: String?,
        vector: [Float]?,
        limit: Int,
        filters: MemoryFilter?
    ) async throws -> [SearchResult]
    func fetch(id: UUID) async throws -> MemoryItem?
    func fetchAll(filters: MemoryFilter?, limit: Int?, offset: Int?) async throws -> [MemoryItem]
    func delete(id: UUID) async throws
    func deleteAll(userId: String?, agentId: String?, runId: String?) async throws
    func reset() async throws
    func logHistory(item: MemoryHistoryItem) async throws
    func fetchHistory(memoryId: UUID?, userId: String?) async throws -> [MemoryHistoryItem]
    func fetchPendingSyncItems() async throws -> [MemoryItem]
    func markSynced(ids: [UUID]) async throws

    // MARK: - Documents & Bookmarks (Supermemory)
    func saveDocument(doc: DocumentItem) async throws
    func searchDocuments(query: String?, vector: [Float]?, limit: Int, userId: String?) async throws -> [DocumentItem]

    // MARK: - Recall Memory (Letta/MemGPT)
    func logRecallMessage(message: RecallMessage) async throws
    func fetchRecallMessages(userId: String?, agentId: String?, runId: String?, limit: Int?) async throws -> [RecallMessage]

    // MARK: - Conversation Summaries (Zep)
    func saveSummary(summary: ConversationSummary) async throws
    func fetchSummary(userId: String?, agentId: String?, runId: String?) async throws -> ConversationSummary?
}

extension VectorStore {
    public func fetchAll(filters: MemoryFilter?) async throws -> [MemoryItem] {
        try await fetchAll(filters: filters, limit: nil, offset: nil)
    }
}
