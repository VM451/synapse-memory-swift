import Testing
import Foundation
@testable import Mem0Swift

@Suite("Full Lifecycle & Bulk Operations Integration Tests")
struct FullLifecycleTests {
    
    @Test("batchAdd stores multiple raw memory statements")
    func testBatchAdd() async throws {
        let vectorStore = try LocalVectorStore(inMemory: true)
        let graphStore = try LocalGraphStore(inMemory: true)
        let config = Mem0Config(
            llmProvider: MockLLMProvider(),
            embeddingProvider: MockEmbeddingProvider(vectorDimension: 64),
            customVectorStore: vectorStore,
            customGraphStore: graphStore,
            enableAutoSync: false,
            enableSpotlightIndexing: false
        )
        let client = try await Mem0Client(config: config)

        let statements = [
            "User likes Swift programming language.",
            "User builds native macOS applications.",
            "User uses CloudKit for private data synchronization."
        ]

        let added = try await client.batchAdd(memories: statements, userId: "dev_alex")
        #expect(added.count == 3)

        let all = try await client.getAll(userId: "dev_alex")
        #expect(all.count == 3)
    }

    @Test("Paginated getAll retrieves items with limit and offset")
    func testPaginatedGetAll() async throws {
        let vectorStore = try LocalVectorStore(inMemory: true)
        let graphStore = try LocalGraphStore(inMemory: true)
        let config = Mem0Config(
            llmProvider: MockLLMProvider(),
            embeddingProvider: MockEmbeddingProvider(vectorDimension: 64),
            customVectorStore: vectorStore,
            customGraphStore: graphStore,
            enableAutoSync: false,
            enableSpotlightIndexing: false
        )
        let client = try await Mem0Client(config: config)

        for i in 1...10 {
            try await client.add(memory: "Item \(i)", userId: "pager_user")
        }

        let page1 = try await client.getAll(userId: "pager_user", limit: 3, offset: 0)
        #expect(page1.count == 3)

        let page2 = try await client.getAll(userId: "pager_user", limit: 3, offset: 3)
        #expect(page2.count == 3)
        #expect(page1.first?.id != page2.first?.id)
    }

    @Test("deleteAll removes all scoped memories for a specific user")
    func testDeleteAll() async throws {
        let vectorStore = try LocalVectorStore(inMemory: true)
        let graphStore = try LocalGraphStore(inMemory: true)
        let config = Mem0Config(
            llmProvider: MockLLMProvider(),
            embeddingProvider: MockEmbeddingProvider(vectorDimension: 64),
            customVectorStore: vectorStore,
            customGraphStore: graphStore,
            enableAutoSync: false,
            enableSpotlightIndexing: false
        )
        let client = try await Mem0Client(config: config)

        try await client.add(memory: "User 1 note", userId: "u1")
        try await client.add(memory: "User 2 note", userId: "u2")

        try await client.deleteAll(userId: "u1")

        let u1Memories = try await client.getAll(userId: "u1")
        #expect(u1Memories.isEmpty)

        let u2Memories = try await client.getAll(userId: "u2")
        #expect(u2Memories.count == 1)
    }

    @Test("reset wipes entire database")
    func testReset() async throws {
        let vectorStore = try LocalVectorStore(inMemory: true)
        let graphStore = try LocalGraphStore(inMemory: true)
        let config = Mem0Config(
            llmProvider: MockLLMProvider(),
            embeddingProvider: MockEmbeddingProvider(vectorDimension: 64),
            customVectorStore: vectorStore,
            customGraphStore: graphStore,
            enableAutoSync: false,
            enableSpotlightIndexing: false
        )
        let client = try await Mem0Client(config: config)

        try await client.add(memory: "Wipe me out", userId: "u1")
        try await client.updateCoreBlock(key: "key", value: "val")

        try await client.reset()

        let all = try await client.getAll(userId: "u1")
        #expect(all.isEmpty)

        let core = try await client.coreBlock
        #expect(core.isEmpty)
    }
}
