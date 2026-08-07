import Foundation

/// Structured mutation operation returned by the LLM extraction engine.
public struct MemoryOperation: Codable, Sendable {
    public enum Event: String, Codable, Sendable {
        case add = "ADD"
        case update = "UPDATE"
        case delete = "DELETE"
        case noChange = "NO_CHANGE"
    }

    public let event: Event
    public let memory: String
    public let oldMemory: String?
    public let id: String? // Target UUID string if UPDATE or DELETE
    public let metadata: [String: String]?

    public init(
        event: Event,
        memory: String,
        oldMemory: String? = nil,
        id: String? = nil,
        metadata: [String: String]? = nil
    ) {
        self.event = event
        self.memory = memory
        self.oldMemory = oldMemory
        self.id = id
        self.metadata = metadata
    }
}

/// The structured payload returned by LLM extraction.
public struct StructuredExtractionResponse: Codable, Sendable {
    public let memoryOperations: [MemoryOperation]

    enum CodingKeys: String, CodingKey {
        case memoryOperations = "memory_operations"
    }

    public init(memoryOperations: [MemoryOperation]) {
        self.memoryOperations = memoryOperations
    }
}

/// Result returned from `SynapseClient.add()`.
public struct MemoryChangeset: Codable, Sendable {
    public let changes: [MemoryOperation]
    public let affectedItems: [MemoryItem]

    public init(changes: [MemoryOperation], affectedItems: [MemoryItem]) {
        self.changes = changes
        self.affectedItems = affectedItems
    }
}
