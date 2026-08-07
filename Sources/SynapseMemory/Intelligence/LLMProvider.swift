import Foundation

/// Provider interface for Memory Extraction and Reasoning.
public protocol LLMProvider: Sendable {
    /// Generates structured Decodable output from an LLM prompt.
    func generateStructuredOutput<T: Decodable & Sendable>(
        prompt: String,
        responseSchema: T.Type
    ) async throws -> T
}
