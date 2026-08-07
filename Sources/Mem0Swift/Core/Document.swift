import Foundation

/// Represents a chunked document, article, bookmark, or web page stored in the local memory system (inspired by Supermemory).
public struct DocumentItem: Identifiable, Codable, Sendable, Hashable {
    public let id: UUID
    public var title: String
    public var url: String?
    public var content: String
    public var chunkIndex: Int
    public var totalChunks: Int
    public var vector: [Float]
    public var tags: [String]
    
    // Scoping
    public var userId: String?
    public var metadata: [String: String]
    public var createdAt: Date
    public var updatedAt: Date
    public var isDeleted: Bool

    public init(
        id: UUID = UUID(),
        title: String,
        url: String? = nil,
        content: String,
        chunkIndex: Int = 0,
        totalChunks: Int = 1,
        vector: [Float] = [],
        tags: [String] = [],
        userId: String? = nil,
        metadata: [String: String] = [:],
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        isDeleted: Bool = false
    ) {
        self.id = id
        self.title = title
        self.url = url
        self.content = content
        self.chunkIndex = chunkIndex
        self.totalChunks = totalChunks
        self.vector = vector
        self.tags = tags
        self.userId = userId
        self.metadata = metadata
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.isDeleted = isDeleted
    }
}
