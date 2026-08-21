# SynapseMemory 

[![Swift 6.0](https://img.shields.io/badge/Swift-6.0-orange.svg?style=flat)](https://swift.org)
[![Platforms](https://img.shields.io/badge/Platforms-iOS%2017%2B%20%7C%20macOS%2014%2B%20%7C%20visionOS%201%2B%20%7C%20watchOS%2010%2B-black.svg?logo=apple)](https://developer.apple.com)
[![Execution](https://img.shields.io/badge/Execution-Local--First-blue.svg)](https://developer.apple.com)
[![Sync](https://img.shields.io/badge/Sync-CloudKit%20Private%20Database-purple.svg)](https://developer.apple.com/icloud/cloudkit/)
[![Documentation](https://img.shields.io/badge/Docs-docs%2F-purple.svg)](docs/README.md)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

> **Local-first, agentic memory for Apple platforms.**
>
> SynapseMemory provides conversational memory, bi-temporal knowledge graphs, hybrid vector and full-text search, document RAG, on-device providers, and optional private CloudKit sync in a native Swift package.

## ⚡ 30-Second Quick Start

```swift
import SynapseMemory

// 1. Initialize local memory with the default providers and configuration
let memory = try await SynapseClient(config: SynapseConfig())

// 2. Extract memories and knowledge-graph relations from a conversation
try await memory.add(messages: [
    Message(role: .user, content: "I live in Bangkok and build native Swift apps."),
    Message(role: .assistant, content: "I will remember that.")
], userId: "alex_123")

// 3. Search memories with semantic, keyword, and recency scoring
let results = try await memory.search(
    query: "Where does Alex live?",
    userId: "alex_123"
)

for result in results {
    print("\(result.item.memory) — \(result.score)")
}
```

## 📊 Core Capabilities

| Capability | Description |
|---|---|
| **Conversational Memory** | Extract, add, update, delete, and summarize memories from message turns. |
| **Knowledge Graph** | Store and query entity-relation triples with bi-temporal fact history. |
| **Hybrid Search** | Combine Accelerate vector similarity, SQLite FTS5 BM25, and time decay. |
| **Document RAG** | Load PDF, Markdown, code, CSV, JSON, and text files with chunking and citations. |
| **On-Device Intelligence** | Use Apple Foundation Models, Ollama, OpenAI, or mock providers. |
| **Working Memory** | Maintain core memory blocks, recall logs, and rolling dialogue summaries. |
| **Apple Integrations** | Index memories with Core Spotlight, expose App Intents, and schedule maintenance. |
| **Private Sync** | Synchronize memories and graph data across devices with CloudKit private databases. |
| **Agent Tools** | Expose memory operations to SynapseAgent and other tool-calling runtimes. |

## 📚 Documentation (`docs/`)

Explore the complete documentation in the **[`docs/`](docs/README.md)** directory:

| Section | Documentation |
|---|---|
| 🚀 **Getting Started** | [Quick Start](docs/getting-started/quick-start.md) · [Configuration](docs/getting-started/configuration.md) |
| 🏛️ **Architecture** | [System Overview](docs/architecture/overview.md) · [Competitor Comparison](docs/architecture/competitor-comparison.md) |
| 📖 **Memory Guides** | [Conversational Memory](docs/guides/conversational-memory.md) · [Knowledge Graph](docs/guides/knowledge-graph.md) · [Hybrid Search](docs/guides/hybrid-search.md) |
| 📄 **RAG Guides** | [Document Ingestion](docs/guides/document-ingestion.md) · [RAG Pipeline](docs/guides/rag-pipeline.md) |
| ☁️ **Apple Integrations** | [CloudKit Sync](docs/guides/cloudkit-sync.md) · [Apple Integrations](docs/guides/apple-integrations.md) |
| 🛈 **API Reference** | [SynapseClient](docs/api-reference/synapse-client.md) · [Intelligence Providers](docs/api-reference/intelligence-providers.md) |

## 🧪 Testing

Run the Swift test suite from the package directory:

```bash
swift test
```

## ⚖️ License

SynapseMemory is open-source software licensed under the [MIT License](LICENSE).
