import Foundation

/// Primary data entity representing an individual stored user/agent memory.
public struct MemoryItem: Identifiable, Codable, Sendable, Hashable {
    public let id: UUID
    public var memory: String
    public var hash: String
    public var vector: [Float]
    
    // Scoping
    public var userId: String?
    public var agentId: String?
    public var runId: String?
    public var metadata: [String: String]
    
    // Bi-Temporal Attributes
    public var validFrom: Date
    public var validTo: Date?
    public var supersededById: UUID?
    
    // Usage & Time-Decay Attributes
    public var accessCount: Int
    public var lastAccessedAt: Date
    public var scoreWeight: Float
    
    // System Lifecycle
    public var createdAt: Date
    public var updatedAt: Date
    public var isDeleted: Bool
    public var version: Int64

    public init(
        id: UUID = UUID(),
        memory: String,
        hash: String = "",
        vector: [Float] = [],
        userId: String? = nil,
        agentId: String? = nil,
        runId: String? = nil,
        metadata: [String: String] = [:],
        validFrom: Date = Date(),
        validTo: Date? = nil,
        supersededById: UUID? = nil,
        accessCount: Int = 0,
        lastAccessedAt: Date = Date(),
        scoreWeight: Float = 1.0,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        isDeleted: Bool = false,
        version: Int64 = 1
    ) {
        self.id = id
        self.memory = memory
        self.hash = hash.isEmpty ? Self.computeHash(for: memory) : hash
        self.vector = vector
        self.userId = userId
        self.agentId = agentId
        self.runId = runId
        self.metadata = metadata
        self.validFrom = validFrom
        self.validTo = validTo
        self.supersededById = supersededById
        self.accessCount = accessCount
        self.lastAccessedAt = lastAccessedAt
        self.scoreWeight = scoreWeight
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.isDeleted = isDeleted
        self.version = version
    }
    
    /// Utility to compute a SHA256 string hash of the memory text for quick collision checking.
    public static func computeHash(for text: String) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let utf8Data = Data(trimmed.utf8)
        var hash = [UInt8](repeating: 0, count: 32)
        utf8Data.withUnsafeBytes { buffer in
            _ = CC_SHA256(buffer.baseAddress, CC_LONG(buffer.count), &hash)
        }
        return hash.map { String(format: "%02hhx", $0) }.joined()
    }
}

// CommonCrypto import for CC_SHA256
import CommonCrypto
