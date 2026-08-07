import Foundation

/// Represents a directed relationship edge between two entities in the Knowledge Graph.
public struct Relation: Identifiable, Codable, Sendable, Hashable {
    public let id: UUID
    public var sourceEntityId: UUID
    public var targetEntityId: UUID
    public var relationshipType: String
    
    // Scoping & Metadata
    public var userId: String?
    public var metadata: [String: String]
    public var weight: Float
    
    // System Lifecycle
    public var createdAt: Date
    public var updatedAt: Date
    public var isDeleted: Bool
    public var version: Int64

    public init(
        id: UUID = UUID(),
        sourceEntityId: UUID,
        targetEntityId: UUID,
        relationshipType: String,
        userId: String? = nil,
        metadata: [String: String] = [:],
        weight: Float = 1.0,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        isDeleted: Bool = false,
        version: Int64 = 1
    ) {
        self.id = id
        self.sourceEntityId = sourceEntityId
        self.targetEntityId = targetEntityId
        self.relationshipType = relationshipType
        self.userId = userId
        self.metadata = metadata
        self.weight = weight
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.isDeleted = isDeleted
        self.version = version
    }
}

/// A combined graph knowledge triple representation (Subject, Predicate, Object).
public struct GraphTriple: Codable, Sendable, Hashable {
    public let sourceEntityName: String
    public let sourceEntityType: String
    public let relationshipType: String
    public let targetEntityName: String
    public let targetEntityType: String

    public init(
        sourceEntityName: String,
        sourceEntityType: String = "Concept",
        relationshipType: String,
        targetEntityName: String,
        targetEntityType: String = "Concept"
    ) {
        self.sourceEntityName = sourceEntityName
        self.sourceEntityType = sourceEntityType
        self.relationshipType = relationshipType
        self.targetEntityName = targetEntityName
        self.targetEntityType = targetEntityType
    }
}
