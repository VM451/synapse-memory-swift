import Foundation

/// Represents a rolling, compressed dialogue summary of conversation history (inspired by Zep).
public struct ConversationSummary: Identifiable, Codable, Sendable, Hashable {
    public let id: UUID
    public var userId: String?
    public var agentId: String?
    public var runId: String?
    public var summary: String
    public var messageCount: Int
    public var lastMessageTimestamp: Date
    public var createdAt: Date
    public var updatedAt: Date

    public init(
        id: UUID = UUID(),
        userId: String? = nil,
        agentId: String? = nil,
        runId: String? = nil,
        summary: String,
        messageCount: Int,
        lastMessageTimestamp: Date = Date(),
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.agentId = agentId
        self.runId = runId
        self.summary = summary
        self.messageCount = messageCount
        self.lastMessageTimestamp = lastMessageTimestamp
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
