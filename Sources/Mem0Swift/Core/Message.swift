import Foundation

/// Represents a conversational message turn exchanged with an LLM.
public struct Message: Codable, Sendable, Hashable {
    public enum Role: String, Codable, Sendable {
        case user
        case assistant
        case system
    }

    public let id: UUID
    public let role: Role
    public let content: String
    public let timestamp: Date
    public let metadata: [String: String]

    public init(
        id: UUID = UUID(),
        role: Role,
        content: String,
        timestamp: Date = Date(),
        metadata: [String: String] = [:]
    ) {
        self.id = id
        self.role = role
        self.content = content
        self.timestamp = timestamp
        self.metadata = metadata
    }
}
