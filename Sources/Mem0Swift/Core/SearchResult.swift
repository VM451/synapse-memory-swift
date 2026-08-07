import Foundation

/// A scored search result returned by hybrid vector + text search.
public struct SearchResult: Identifiable, Codable, Sendable, Hashable {
    public var id: UUID { item.id }
    public let item: MemoryItem
    public let score: Float
    public let vectorSimilarity: Float?
    public let textRank: Float?

    public init(
        item: MemoryItem,
        score: Float,
        vectorSimilarity: Float? = nil,
        textRank: Float? = nil
    ) {
        self.item = item
        self.score = score
        self.vectorSimilarity = vectorSimilarity
        self.textRank = textRank
    }
}
