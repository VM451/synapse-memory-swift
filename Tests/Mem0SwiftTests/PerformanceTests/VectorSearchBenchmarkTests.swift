import Testing
import Foundation
@testable import Mem0Swift

@Suite("Performance & Scale Benchmarks")
struct VectorSearchBenchmarkTests {
    
    @Test("Accelerate SIMD Vector Search 10k Items Latency SLA < 15ms")
    func testVectorSearchLatency() async throws {
        let count = 10_000
        let dimensions = 384
        let sampleVector = VectorMath.normalize([Float](repeating: 0.1, count: dimensions))
        let vectors = [[Float]](repeating: sampleVector, count: count)
        let queryVector = VectorMath.normalize([Float](repeating: 0.15, count: dimensions))
        
        let clock = ContinuousClock()
        let duration = clock.measure {
            for v in vectors {
                _ = VectorMath.cosineSimilarity(queryVector, v)
            }
        }
        
        // SLA: 10,000 Accelerate SIMD cosine similarity calculations must execute in < 15ms on Apple Silicon
        #expect(duration < .milliseconds(15))
    }
}
