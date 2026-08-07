import Foundation
import NaturalLanguage

/// On-device privacy-preserving embedding provider leveraging Apple's NaturalLanguage (NLEmbedding) and CoreML models.
public final class AppleFoundationModelProvider: EmbeddingProvider, @unchecked Sendable {
    public let vectorDimension: Int
    private let embedder: NLEmbedding?

    public init(language: NLLanguage = .english) {
        self.embedder = NLEmbedding.wordEmbedding(for: language)
        self.vectorDimension = embedder?.dimension ?? 512
    }

    public func embed(text: String) async throws -> [Float] {
        guard let embedder = embedder else {
            return try await MockEmbeddingProvider(vectorDimension: vectorDimension).embed(text: text)
        }
        
        let words = text.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
        guard !words.isEmpty else {
            return [Float](repeating: 0.0, count: vectorDimension)
        }
        
        var accumVector = [Float](repeating: 0.0, count: vectorDimension)
        var count: Float = 0.0
        
        for word in words {
            if let vectorDouble = embedder.vector(for: word) {
                for i in 0..<min(vectorDimension, vectorDouble.count) {
                    accumVector[i] += Float(vectorDouble[i])
                }
                count += 1.0
            }
        }
        
        if count > 0 {
            for i in 0..<vectorDimension {
                accumVector[i] /= count
            }
        }
        
        return VectorMath.normalize(accumVector)
    }

    public func embed(batch: [String]) async throws -> [[Float]] {
        var results: [[Float]] = []
        for text in batch {
            results.append(try await embed(text: text))
        }
        return results
    }
}
