# Intelligence Providers API Reference

SynapseMemory decouples language generation and embedding generation through two core Swift protocols: `LLMProvider` and `EmbeddingProvider`.

---

## 📐 Provider Protocols

```swift
/// Protocol defining LLM text generation capabilities for extraction and resolution.
public protocol LLMProvider: Sendable {
    func generate(prompt: String) async throws -> String
}

/// Protocol defining vector embedding generation capabilities.
public protocol EmbeddingProvider: Sendable {
    func embed(text: String) async throws -> [Float]
    func embed(texts: [String]) async throws -> [[Float]]
}
```

---

## 🍏 Built-In Providers

### 1. `AppleFoundationModelProvider` (Default)
- Uses Apple's native system Foundation Models for zero-config, on-device intelligence on iOS 27+, macOS 27+, visionOS 27+, and watchOS 20+.
- Zero API keys, zero network latency, zero costs.

```swift
let provider = AppleFoundationModelProvider()
```

---

### 2. `OllamaProvider`
- Connects to local Ollama servers running on macOS or Linux for offline local LLMs (e.g. Llama 3, Mistral, Gemma).

```swift
let provider = OllamaProvider(
    baseURL: URL(string: "http://localhost:11434")!,
    model: "llama3"
)
```

---

### 3. `OpenAIProvider`
- Connects to OpenAI REST API endpoints (or compatible proxies like VLLM / LM Studio).

```swift
let provider = OpenAIProvider(
    apiKey: "sk-proj-...",
    model: "gpt-4o-mini",
    embeddingModel: "text-embedding-3-small"
)
```

---

### 4. `MockProviders`
- Designed for unit testing, continuous integration (CI) pipelines, and fast UI previews without loading actual models or network calls.

```swift
let mockLLM = MockLLMProvider(mockResponse: "{ \"memories\": [] }")
let mockEmbedder = MockEmbeddingProvider(dimension: 1536)
```
