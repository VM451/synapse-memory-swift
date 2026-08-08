# Configuration Guide

`SynapseConfig` allows you to customize the behavior of `SynapseClient`, including vector dimensions, storage locations, memory decay parameters, and intelligence providers.

---

## 🛠️ `SynapseConfig` Options

### Property Breakdown

| Property | Type | Default Value | Description |
|---|---|---|---|
| `dbPath` | `String?` | `nil` (In-memory/default directory) | Custom file path to the SQLite database. |
| `vectorDimension` | `Int` | `1536` | Vector embedding dimension (e.g. 1536 for OpenAI, 384/768 for local models). |
| `similarityMetric` | `SimilarityMetric` | `.cosine` | Vector metric (`.cosine`, `.dotProduct`, `.euclidean`). |
| `enableCloudKit` | `Bool` | `true` | Toggles automatic private CloudKit iCloud synchronization. |
| `cloudKitContainerIdentifier` | `String?` | `nil` (Uses `CKContainer.default()`) | Custom CloudKit container ID. |
| `llmProvider` | `LLMProvider` | `AppleFoundationModelProvider()` | LLM provider for memory extraction and entity resolution. |
| `embeddingProvider` | `EmbeddingProvider` | `AppleFoundationModelProvider()` | Embedding provider for generating dense vector representations. |
| `halfLifeDays` | `Double` | `30.0` | Exponential decay half-life in days used for search scoring. |
| `maxWorkingMemoryTokens` | `Int` | `2048` | Token budget threshold before triggering rolling dialogue summarization. |

---

## 💡 Configuration Examples

### 1. Default On-Device Configuration (Zero-Config)

```swift
import SynapseMemory

// Uses Apple Foundation Models, default SQLite path, and CloudKit Sync
let config = SynapseConfig()
let synapse = try await SynapseClient(config: config)
```

---

### 2. Local Ollama LLM + Custom SQLite Path

```swift
import SynapseMemory

let ollama = OllamaProvider(baseURL: URL(string: "http://localhost:11434")!, model: "llama3")

let config = SynapseConfig(
    dbPath: "/path/to/my_app_memory.sqlite",
    vectorDimension: 768,
    similarityMetric: .cosine,
    enableCloudKit: false,
    llmProvider: ollama,
    embeddingProvider: ollama
)

let synapse = try await SynapseClient(config: config)
```

---

### 3. Custom OpenAI Provider Configuration

```swift
import SynapseMemory

let openAI = OpenAIProvider(apiKey: "sk-proj-...", model: "gpt-4o-mini")

let config = SynapseConfig(
    vectorDimension: 1536,
    similarityMetric: .cosine,
    enableCloudKit: true,
    cloudKitContainerIdentifier: "iCloud.com.example.AgentApp",
    llmProvider: openAI,
    embeddingProvider: openAI,
    halfLifeDays: 14.0 // Recency decays faster (14-day half life)
)

let synapse = try await SynapseClient(config: config)
```

---

## 🔒 Concurrency & Thread Safety

`SynapseClient` is implemented as a Swift **Actor** (`public actor SynapseClient`). All calls are isolated and thread-safe under Swift 6 strict concurrency (`@Sendable`).
