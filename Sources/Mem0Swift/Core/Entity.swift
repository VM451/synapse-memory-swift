import Foundation

/// Represents a distinct entity node in the local Knowledge Graph memory.
public struct Entity: Identifiable, Codable, Sendable, Hashable {
    public let id: UUID
    public var name: String
    public var type: String
    
    // Scoping
    public var userId: String?
    public var agentId: String?
    public var runId: String?
    public var metadata: [String: String]
    
    // System Lifecycle
    public var createdAt: Date
    public var updatedAt: Date
    public var isDeleted: Bool
    public var version: Int64

    public init(
        id: UUID = UUID(),
        name: String,
        type: String = "Concept",
        userId: String? = nil,
        agentId: String? = nil,
        runId: String? = nil,
        metadata: [String: String] = [:],
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        isDeleted: Bool = false,
        version: Int64 = 1
    ) {
        self.id = id
        self.name = name
        self.type = type
        self.userId = userId
        self.agentId = agentId
        self.runId = runId
        self.metadata = metadata
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.isDeleted = isDeleted
        self.version = version
    }
}
