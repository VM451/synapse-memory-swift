import Foundation

/// Configuration options for initializing Mem0Client.
public struct Mem0Config: Sendable {
    public var llmProvider: LLMProvider
    public var embeddingProvider: EmbeddingProvider
    public var customVectorStore: VectorStore?
    public var cloudKitContainerId: String?
    public var enableAutoSync: Bool
    public var enableSpotlightIndexing: Bool
    public var databasePath: String?

    public init(
        llmProvider: LLMProvider,
        embeddingProvider: EmbeddingProvider,
        customVectorStore: VectorStore? = nil,
        cloudKitContainerId: String? = nil,
        enableAutoSync: Bool = true,
        enableSpotlightIndexing: Bool = true,
        databasePath: String? = nil
    ) {
        self.llmProvider = llmProvider
        self.embeddingProvider = embeddingProvider
        self.customVectorStore = customVectorStore
        self.cloudKitContainerId = cloudKitContainerId
        self.enableAutoSync = enableAutoSync
        self.enableSpotlightIndexing = enableSpotlightIndexing
        self.databasePath = databasePath
    }
}
