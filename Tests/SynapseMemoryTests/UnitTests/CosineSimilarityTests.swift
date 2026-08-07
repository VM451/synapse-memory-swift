import Testing
@testable import SynapseMemory

@Suite("Vector Math & Cosine Similarity Unit Tests")
struct CosineSimilarityTests {
    
    @Test("Identical Vectors return similarity 1.0")
    func testIdenticalVectors() {
        let v1: [Float] = [1.0, 0.0, 0.0, 0.5]
        let sim = VectorMath.cosineSimilarity(v1, v1)
        #expect(abs(sim - 1.0) < 0.0001)
    }

    @Test("Orthogonal Vectors return similarity 0.0")
    func testOrthogonalVectors() {
        let v1: [Float] = [1.0, 0.0, 0.0]
        let v2: [Float] = [0.0, 1.0, 0.0]
        let sim = VectorMath.cosineSimilarity(v1, v2)
        #expect(abs(sim - 0.0) < 0.0001)
    }

    @Test("Opposite Vectors return similarity -1.0")
    func testOppositeVectors() {
        let v1: [Float] = [1.0, 2.0, 3.0]
        let v2: [Float] = [-1.0, -2.0, -3.0]
        let sim = VectorMath.cosineSimilarity(v1, v2)
        #expect(abs(sim - (-1.0)) < 0.0001)
    }

    @Test("Zero Vectors return similarity 0.0 without division by zero crash")
    func testZeroVectorHandling() {
        let zero: [Float] = [0.0, 0.0, 0.0]
        let v1: [Float] = [1.0, 2.0, 3.0]
        let sim = VectorMath.cosineSimilarity(zero, v1)
        #expect(sim == 0.0)
    }

    @Test("Vector Normalization converts vector into unit length")
    func testVectorNormalization() {
        let v: [Float] = [3.0, 4.0]
        let normalized = VectorMath.normalize(v)
        #expect(abs(normalized[0] - 0.6) < 0.0001)
        #expect(abs(normalized[1] - 0.8) < 0.0001)
    }
}
