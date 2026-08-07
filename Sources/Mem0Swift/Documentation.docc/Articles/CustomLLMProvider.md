# Implementing Custom LLM & Embedding Providers

Extend Mem0Swift with custom local or remote inference engines (e.g. Ollama, CoreML, Cohere).

## Overview

Mem0Swift relies on clean protocols to inject embedding models and structured extraction LLMs.

### Implementing `EmbeddingProvider`

```swift
import Mem0Swift

public struct CustomEmbeddingProvider: EmbeddingProvider {
    public var vectorDimension: Int { 768 }

    public func embed(text: String) async throws -> [Float] {
        // Send request to custom backend / CoreML model
        return [Float](repeating: 0.1, count: vectorDimension)
    }

    public func embed(batch: [String]) async throws -> [[Float]] {
        var results: [[Float]] = []
        for text in batch {
            results.append(try await embed(text: text))
        }
        return results
    }
}
```

### Implementing `LLMProvider`

```swift
import Mem0Swift

public struct CustomLLMProvider: LLMProvider {
    public func generateStructuredOutput<T: Decodable & Sendable>(
        prompt: String,
        responseSchema: T.Type
    ) async throws -> T {
        // Call local model (e.g. Ollama or Apple Foundation Model)
        let jsonString = """
        {
          "memory_operations": []
        }
        """
        let data = jsonString.data(using: .utf8)!
        return try JSONDecoder().decode(T.self, from: data)
    }
}
```
