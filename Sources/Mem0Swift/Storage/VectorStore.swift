import Foundation

/// Abstract storage interface for storing, searching, and managing memories locally.
public protocol VectorStore: Sendable {
    /// Save or update a memory item.
    func save(item: MemoryItem) async throws
    
    /// Save multiple memory items atomically.
    func saveBatch(items: [MemoryItem]) async throws
    
    /// Perform hybrid vector + FTS search over stored memories.
    func search(
        query: String?,
        vector: [Float]?,
        limit: Int,
        filters: MemoryFilter?
    ) async throws -> [SearchResult]
    
    /// Fetch a memory by its UUID.
    func fetch(id: UUID) async throws -> MemoryItem?
    
    /// Fetch all memories matching optional filters.
    func fetchAll(filters: MemoryFilter?) async throws -> [MemoryItem]
    
    /// Soft or hard delete a memory item.
    func delete(id: UUID) async throws
    
    /// Log an audit history event.
    func logHistory(item: MemoryHistoryItem) async throws
    
    /// Fetch audit history for a memory item or user.
    func fetchHistory(memoryId: UUID?, userId: String?) async throws -> [MemoryHistoryItem]
    
    /// Pending CloudKit sync records query.
    func fetchPendingSyncItems() async throws -> [MemoryItem]
    
    /// Mark items as synced with CloudKit.
    func markSynced(ids: [UUID]) async throws
}
