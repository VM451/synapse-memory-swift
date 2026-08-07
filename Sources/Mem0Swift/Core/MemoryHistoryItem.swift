import Foundation

/// Action type for memory audit history.
public enum MemoryAction: String, Codable, Sendable {
    case add = "ADD"
    case update = "UPDATE"
    case delete = "DELETE"
}

/// Audit log record tracking mutations over time for transparency.
public struct MemoryHistoryItem: Identifiable, Codable, Sendable, Hashable {
    public let id: UUID
    public let memoryId: UUID
    public let action: MemoryAction
    public let oldMemory: String?
    public let newMemory: String?
    public let timestamp: Date
    public let userId: String?

    public init(
        id: UUID = UUID(),
        memoryId: UUID,
        action: MemoryAction,
        oldMemory: String? = nil,
        newMemory: String? = nil,
        timestamp: Date = Date(),
        userId: String? = nil
    ) {
        self.id = id
        self.memoryId = memoryId
        self.action = action
        self.oldMemory = oldMemory
        self.newMemory = newMemory
        self.timestamp = timestamp
        self.userId = userId
    }
}
