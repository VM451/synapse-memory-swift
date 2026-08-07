import Testing
import Foundation
@testable import Mem0Swift

@Suite("Memory Extraction Integration Tests")
struct MemoryExtractionTests {
    
    @Test("Extract and ADD new memory from conversation turns")
    func testExtractionAddFlow() async throws {
        let store = try LocalVectorStore(inMemory: true)
        let embedder = MockEmbeddingProvider()
        let llm = MockLLMProvider(mockOperations: [
            MemoryOperation(event: .add, memory: "User prefers dark mode UI.")
        ])

        let extractor = MemoryExtractor(vectorStore: store, embeddingProvider: embedder, llmProvider: llm)
        let messages = [
            Message(role: .user, content: "Please switch my app theme to dark mode.")
        ]

        let changeset = try await extractor.extractAndApply(messages: messages, userId: "alex")

        #expect(changeset.changes.count == 1)
        #expect(changeset.affectedItems.count == 1)
        #expect(changeset.affectedItems.first?.memory == "User prefers dark mode UI.")

        let saved = try await store.fetchAll(filters: MemoryFilter(userId: "alex"))
        #expect(saved.count == 1)
    }

    @Test("Extract and UPDATE existing memory fact")
    func testExtractionUpdateFlow() async throws {
        let store = try LocalVectorStore(inMemory: true)
        let embedder = MockEmbeddingProvider()

        let initial = MemoryItem(memory: "User lives in Seattle", userId: "alex")
        try await store.save(item: initial)

        let llm = MockLLMProvider(mockOperations: [
            MemoryOperation(
                event: .update,
                memory: "User moved to San Francisco",
                oldMemory: "User lives in Seattle",
                id: initial.id.uuidString
            )
        ])

        let extractor = MemoryExtractor(vectorStore: store, embeddingProvider: embedder, llmProvider: llm)
        let messages = [
            Message(role: .user, content: "I just moved from Seattle to San Francisco!")
        ]

        let changeset = try await extractor.extractAndApply(messages: messages, userId: "alex")

        #expect(changeset.affectedItems.count == 1)
        #expect(changeset.affectedItems.first?.memory == "User moved to San Francisco")

        let oldItem = try await store.fetch(id: initial.id)
        #expect(oldItem?.validTo != nil)
        #expect(oldItem?.supersededById == changeset.affectedItems.first?.id)
    }
}
