import Testing
import Foundation
@testable import Mem0Swift

@Suite("Thread Safety & Concurrency Stress Tests")
struct SQLiteFTS5PerformanceTests {
    
    @Test("100 Parallel Tasks concurrent actor read/write safety")
    func testConcurrentActorReadWrite() async throws {
        let store = try LocalVectorStore(inMemory: true)
        
        await withTaskGroup(of: Void.self) { group in
            for i in 0..<100 {
                group.addTask {
                    let item = MemoryItem(
                        memory: "Concurrent thread memory turn \(i)",
                        vector: [Float(i) / 100.0, 0.5, 0.2],
                        userId: "thread_user_\(i % 5)"
                    )
                    try? await store.save(item: item)
                    _ = try? await store.search(
                        query: "memory",
                        vector: [0.1, 0.5, 0.2],
                        limit: 3,
                        filters: MemoryFilter(userId: "thread_user_\(i % 5)")
                    )
                }
            }
        }
        
        let totalCount = try await store.fetchAll(filters: MemoryFilter(includeDeleted: true))
        #expect(totalCount.count == 100)
    }
}
