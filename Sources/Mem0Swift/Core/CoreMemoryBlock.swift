import Foundation

/// Active working memory block held directly in prompt context (Letta/MemGPT inspired).
public struct CoreMemoryBlock: Codable, Sendable, Hashable {
    public var blocks: [String: String]
    public var updatedAt: Date

    public init(blocks: [String: String] = [:], updatedAt: Date = Date()) {
        self.blocks = blocks
        self.updatedAt = updatedAt
    }

    public mutating func update(key: String, value: String) {
        blocks[key] = value
        updatedAt = Date()
    }

    public mutating func remove(key: String) {
        blocks.removeValue(forKey: key)
        updatedAt = Date()
    }
}
