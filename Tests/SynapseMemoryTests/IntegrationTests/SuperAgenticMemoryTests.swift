import Testing
import Foundation
@testable import SynapseMemory

@Suite("Super Agentic Memory Suite (Supermemory, Letta, Zep Convergence)")
struct SuperAgenticMemoryTests {

    @Test("Supermemory document ingestion and chunked search")
    func testDocumentIngestionAndSearch() async throws {
        let vectorStore = try LocalVectorStore(inMemory: true)
        let graphStore = try LocalGraphStore(inMemory: true)
        let config = SynapseConfig(
            llmProvider: MockLLMProvider(),
            embeddingProvider: MockEmbeddingProvider(vectorDimension: 64),
            customVectorStore: vectorStore,
            customGraphStore: graphStore,
            enableAutoSync: false,
            enableSpotlightIndexing: false
        )
        let client = try await SynapseClient(config: config)

        let article = """
        Apple Intelligence introduces personal intelligence systems to iPhone, iPad, and Mac.
        It combines generative models with personal context to deliver useful and relevant intelligence.
        On-device processing ensures user privacy without transmitting personal data to remote servers.
        CloudKit powers private database synchronization with end-to-end security guarantees.
        """

        let docs = try await client.ingest(
            content: article,
            title: "Apple Intelligence Architecture Guide",
            url: "https://developer.apple.com",
            userId: "researcher_alex",
            tags: ["apple", "ai", "privacy"]
        )

        #expect(!docs.isEmpty)
        #expect(docs.first?.title == "Apple Intelligence Architecture Guide")
        #expect(docs.first?.tags.contains("apple") == true)

        let searchResults = try await client.searchDocuments(
            query: "Apple Intelligence on-device privacy",
            userId: "researcher_alex",
            limit: 3
        )
        #expect(!searchResults.isEmpty)
        #expect(searchResults.first?.title == "Apple Intelligence Architecture Guide")
    }

    @Test("Letta/MemGPT hierarchical recall memory logging and retrieval")
    func testHierarchicalRecallMemory() async throws {
        let vectorStore = try LocalVectorStore(inMemory: true)
        let graphStore = try LocalGraphStore(inMemory: true)
        let config = SynapseConfig(
            llmProvider: MockLLMProvider(),
            embeddingProvider: MockEmbeddingProvider(vectorDimension: 64),
            customVectorStore: vectorStore,
            customGraphStore: graphStore,
            enableAutoSync: false,
            enableSpotlightIndexing: false
        )
        let client = try await SynapseClient(config: config)

        let turns = [
            Message(role: .user, content: "What is my favorite language?"),
            Message(role: .assistant, content: "You told me earlier that you love Swift!")
        ]

        try await client.add(messages: turns, userId: "alex_recall")

        let recallHistory = try await client.recall(userId: "alex_recall")
        #expect(recallHistory.count == 2)
        #expect(recallHistory.first?.role == .user)
        #expect(recallHistory.first?.content == "What is my favorite language?")
    }

    @Test("Zep rolling dialogue summarization")
    func testZepDialogueSummarization() async throws {
        let vectorStore = try LocalVectorStore(inMemory: true)
        let graphStore = try LocalGraphStore(inMemory: true)
        let config = SynapseConfig(
            llmProvider: MockLLMProvider(),
            embeddingProvider: MockEmbeddingProvider(vectorDimension: 64),
            customVectorStore: vectorStore,
            customGraphStore: graphStore,
            enableAutoSync: false,
            enableSpotlightIndexing: false
        )
        let client = try await SynapseClient(config: config)

        let messages = [
            Message(role: .user, content: "I am relocating to Tokyo next month."),
            Message(role: .assistant, content: "Congratulations! Tokyo is a fantastic city.")
        ]

        let summary = try await client.summarize(messages: messages, userId: "user_tokyo")
        #expect(!summary.summary.isEmpty)
        #expect(summary.messageCount == 2)

        let fetchedSummary = try await client.getConversationSummary(userId: "user_tokyo")
        #expect(fetchedSummary != nil)
        #expect(fetchedSummary?.summary == summary.summary)
    }
}
