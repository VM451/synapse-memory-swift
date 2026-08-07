import Testing
import Foundation
@testable import SynapseMemory

@Suite("Bi-Temporal Knowledge Graph Unit Tests")
struct BiTemporalGraphTests {
    
    @Test("Fact superseding links old memory validTo date to new memory id")
    func testFactSuperseding() async throws {
        let store = try LocalVectorStore(inMemory: true)
        let t1 = Date().addingTimeInterval(-86400) // 1 day ago
        
        var initialFact = MemoryItem(
            memory: "User lives in Tokyo",
            userId: "user_japan",
            validFrom: t1
        )
        try await store.save(item: initialFact)

        let t2 = Date() // Today
        let newFact = MemoryItem(
            memory: "User moved to London",
            userId: "user_japan",
            validFrom: t2
        )

        // Supersede initial fact
        initialFact.validTo = t2
        initialFact.supersededById = newFact.id

        try await store.save(item: initialFact)
        try await store.save(item: newFact)

        // Query active memories at t2 (Today)
        let activeToday = try await store.fetchAll(filters: MemoryFilter(userId: "user_japan", activeAt: t2))
        #expect(activeToday.count == 1)
        #expect(activeToday.first?.memory == "User moved to London")

        // Query active memories at t1 (Yesterday)
        let activeYesterday = try await store.fetchAll(filters: MemoryFilter(userId: "user_japan", activeAt: t1.addingTimeInterval(3600)))
        #expect(activeYesterday.count == 1)
        #expect(activeYesterday.first?.memory == "User lives in Tokyo")
    }
}
