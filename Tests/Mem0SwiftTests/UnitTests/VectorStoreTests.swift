import Testing
import Foundation
@testable import Mem0Swift

@Suite("Local Vector Store Unit Tests")
struct VectorStoreTests {
    
    @Test("Save and fetch MemoryItem by ID")
    func testSaveAndFetch() async throws {
        let store = try LocalVectorStore(inMemory: true)
        let item = MemoryItem(
            memory: "User lives in Bangkok",
            vector: [0.1, 0.2, 0.3],
            userId: "user_bkk"
        )
        
        try await store.save(item: item)
        let fetched = try await store.fetch(id: item.id)
        
        #expect(fetched != nil)
        #expect(fetched?.memory == "User lives in Bangkok")
        #expect(fetched?.userId == "user_bkk")
        #expect(fetched?.vector == [0.1, 0.2, 0.3])
    }

    @Test("Soft delete memory marks item deleted and excludes from search")
    func testSoftDelete() async throws {
        let store = try LocalVectorStore(inMemory: true)
        let item = MemoryItem(memory: "Temporary note", vector: [0.5, 0.5])
        try await store.save(item: item)
        
        try await store.delete(id: item.id)
        
        let activeMemories = try await store.fetchAll(filters: MemoryFilter(includeDeleted: false))
        #expect(!activeMemories.contains(where: { $0.id == item.id }))
        
        let allMemories = try await store.fetchAll(filters: MemoryFilter(includeDeleted: true))
        #expect(allMemories.contains(where: { $0.id == item.id }))
    }
}
