import Foundation

/// Defines the hierarchical memory tiers inspired by Letta / MemGPT and cognitive memory architectures.
public enum MemoryTier: String, Codable, Sendable {
    /// In-context editable key-value working persona blocks (fast, direct, token-budgeted).
    case working
    
    /// Chronological raw dialogue log for audit, exact replay, and short-term dialogue recall.
    case recall
    
    /// Infinite long-term semantic storage powered by SIMD vector indexing and Knowledge Graph triples.
    case archival
}

/// A single message record in the chronological recall memory tier.
public struct RecallMessage: Identifiable, Codable, Sendable, Hashable {
    public let id: UUID
    public var role: Message.Role
    public var content: String
    public var userId: String?
    public var agentId: String?
    public var runId: String?
    public var timestamp: Date

    public init(
        id: UUID = UUID(),
        role: Message.Role,
        content: String,
        userId: String? = nil,
        agentId: String? = nil,
        runId: String? = nil,
        timestamp: Date = Date()
    ) {
        self.id = id
        self.role = role
        self.content = content
        self.userId = userId
        self.agentId = agentId
        self.runId = runId
        self.timestamp = timestamp
    }
}
