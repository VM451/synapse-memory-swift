import Foundation
import Accelerate

/// SIMD Vector math operations powered by Apple's Accelerate vDSP framework.
public enum VectorMath: Sendable {
    /// Computes cosine similarity between two equal-length float vectors using Accelerate vDSP.
    /// Range: [-1.0, 1.0] (for normalized unit vectors: [0.0, 1.0])
    public static func cosineSimilarity(_ a: [Float], _ b: [Float]) -> Float {
        guard a.count == b.count, !a.isEmpty else { return 0.0 }
        
        var dotProduct: Float = 0.0
        var normA: Float = 0.0
        var normB: Float = 0.0
        
        vDSP_dotpr(a, 1, b, 1, &dotProduct, vDSP_Length(a.count))
        vDSP_dotpr(a, 1, a, 1, &normA, vDSP_Length(a.count))
        vDSP_dotpr(b, 1, b, 1, &normB, vDSP_Length(a.count))
        
        let denominator = sqrt(normA) * sqrt(normB)
        return denominator == 0 ? 0 : (dotProduct / denominator)
    }

    /// Computes Euclidean distance between two float vectors using Accelerate vDSP.
    public static func euclideanDistance(_ a: [Float], _ b: [Float]) -> Float {
        guard a.count == b.count, !a.isEmpty else { return Float.greatestFiniteMagnitude }
        
        var difference = [Float](repeating: 0.0, count: a.count)
        vDSP_vsub(b, 1, a, 1, &difference, 1, vDSP_Length(a.count))
        
        var distanceSquared: Float = 0.0
        vDSP_svesq(difference, 1, &distanceSquared, vDSP_Length(a.count))
        return sqrt(distanceSquared)
    }

    /// Normalizes a float vector in-place or returns a normalized copy.
    public static func normalize(_ a: [Float]) -> [Float] {
        guard !a.isEmpty else { return [] }
        var normSq: Float = 0.0
        vDSP_svesq(a, 1, &normSq, vDSP_Length(a.count))
        let norm = sqrt(normSq)
        guard norm > 0 else { return a }
        
        var result = [Float](repeating: 0.0, count: a.count)
        var divisor = norm
        vDSP_vsdiv(a, 1, &divisor, &result, 1, vDSP_Length(a.count))
        return result
    }
}
