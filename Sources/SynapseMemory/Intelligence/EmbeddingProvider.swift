import Foundation

/// Provider interface for Generating Vector Embeddings.
public protocol EmbeddingProvider: Sendable {
    /// Dimension size of generated float vectors (e.g. 1536 for OpenAI text-embedding-3-small, 768 for NLEmbedder).
    var vectorDimension: Int { get }
    
    /// Embed a single text string into a float array vector.
    func embed(text: String) async throws -> [Float]
    
    /// Embed a batch of text strings into an array of float array vectors.
    func embed(batch: [String]) async throws -> [[Float]]
}
