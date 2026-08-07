import Foundation

/// Mock embedding provider for testing and offline development.
public struct MockEmbeddingProvider: EmbeddingProvider {
    public let vectorDimension: Int
    
    public init(vectorDimension: Int = 128) {
        self.vectorDimension = vectorDimension
    }
    
    public func embed(text: String) async throws -> [Float] {
        // Deterministic pseudo-vector based on hash of text
        let hash = abs(text.hashValue)
        var vector = [Float](repeating: 0.0, count: vectorDimension)
        for i in 0..<vectorDimension {
            let val = Float((hash + i * 31) % 100) / 100.0
            vector[i] = val
        }
        return VectorMath.normalize(vector)
    }
    
    public func embed(batch: [String]) async throws -> [[Float]] {
        var results: [[Float]] = []
        for text in batch {
            results.append(try await embed(text: text))
        }
        return results
    }
}

/// Mock LLM provider for testing and offline development.
public struct MockLLMProvider: LLMProvider {
    public var mockOperations: [MemoryOperation]
    
    public init(mockOperations: [MemoryOperation] = []) {
        self.mockOperations = mockOperations
    }
    
    public func generateStructuredOutput<T: Decodable & Sendable>(
        prompt: String,
        responseSchema: T.Type
    ) async throws -> T {
        if T.self == StructuredExtractionResponse.self {
            let response = StructuredExtractionResponse(memoryOperations: mockOperations)
            return response as! T
        }
        
        let json = "{}"
        let data = json.data(using: .utf8)!
        return try JSONDecoder().decode(T.self, from: data)
    }
}
