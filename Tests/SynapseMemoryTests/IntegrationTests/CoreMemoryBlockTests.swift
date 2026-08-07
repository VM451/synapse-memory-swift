import Testing
import Foundation
@testable import SynapseMemory

@Suite("Core Memory Working Block Integration Tests")
struct CoreMemoryBlockTests {
    
    @Test("Working core memory block set and get operations")
    func testCoreMemorySetAndGet() async throws {
        let store = try LocalVectorStore(inMemory: true)
        
        try await store.setCoreMemoryBlock(key: "human_name", value: "Alex")
        try await store.setCoreMemoryBlock(key: "persona", value: "Socratic Coding Tutor")

        let blocks = try await store.getCoreMemoryBlock()
        #expect(blocks["human_name"] == "Alex")
        #expect(blocks["persona"] == "Socratic Coding Tutor")
    }
}
