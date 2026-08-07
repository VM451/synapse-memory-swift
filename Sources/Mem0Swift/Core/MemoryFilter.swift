import Foundation

/// Criteria for filtering memories during vector/text search or retrieval operations.
public struct MemoryFilter: Codable, Sendable, Hashable {
    public var userId: String?
    public var agentId: String?
    public var runId: String?
    public var metadata: [String: String]?
    public var includeDeleted: Bool
    public var activeAt: Date? // Bi-temporal check: validFrom <= activeAt && (validTo == nil || validTo > activeAt)

    public init(
        userId: String? = nil,
        agentId: String? = nil,
        runId: String? = nil,
        metadata: [String: String]? = nil,
        includeDeleted: Bool = false,
        activeAt: Date? = Date()
    ) {
        self.userId = userId
        self.agentId = agentId
        self.runId = runId
        self.metadata = metadata
        self.includeDeleted = includeDeleted
        self.activeAt = activeAt
    }
}
