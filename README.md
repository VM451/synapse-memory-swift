# SynapseMemory 

[![Swift 6.0](https://img.shields.io/badge/Swift-6.0-orange.svg?style=flat)](https://swift.org)
[![Target Platform](https://img.shields.io/badge/Platform-iOS%2027+%20|%20macOS%2027+%20|%20visionOS%2027+%20|%20watchOS%2020+-black.svg?logo=apple)](https://developer.apple.com)
[![Storage](https://img.shields.io/badge/Storage-Apple%20CloudKit%20Private%20Sync-blue.svg)](https://developer.apple.com/icloud/cloudkit/)
[![Cost](https://img.shields.io/badge/Hosting%20Cost-$0.00%20(Zero%20Servers)-green.svg)](https://github.com/VM451/synapse-memory-swift)
[![Documentation](https://img.shields.io/badge/Docs-docs%2F-purple.svg)](docs/README.md)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

> **The Ultimate Local-First Agentic Memory Framework for Apple Silicon.**
> 
> Uniting the best architectural innovations of **Mem0**, **Supermemory**, **Letta/MemGPT**, and **Zep** into a unified, lightweight native Swift library. **100% on-device execution with zero cloud hosting costs**, seamlessly synced across user Apple devices via **Apple CloudKit private database**.

---

## ⚡ 30-Second Quick Start

```swift
import SynapseMemory

// 1. Initialize SynapseClient (Defaults to Apple Foundation Models + CloudKit Sync)
let synapse = try await SynapseClient(config: SynapseConfig())

// 2. Add conversational turns (Extracts memories, knowledge graph triples & recall logs)
let messages = [
    Message(role: .user, content: "Hi! I am Alex, I live in Bangkok, and I build native Swift apps."),
    Message(role: .assistant, content: "Great to meet you Alex! I will remember you live in Bangkok.")
]
try await synapse.add(messages: messages, userId: "alex_123")

// 3. Ingest documents and web bookmarks with auto-tagging (Supermemory feature)
try await synapse.ingest(
    content: "Apple Intelligence combines generative models with on-device personal context...",
    title: "Apple Intelligence Notes",
    userId: "alex_123",
    tags: ["apple", "ai", "privacy"]
)

// 4. Hybrid Search (Accelerate SIMD + SQLite FTS5 + Time-Decay)
let results = try await synapse.search(query: "Where does Alex live?", userId: "alex_123")
for item in results {
    print("Found Memory: \(item.item.memory) (Score: \(item.score))")
}

// 5. Query Knowledge Graph Triples (Mem0 & Graphiti feature)
let triples = try await synapse.getRelations(userId: "alex_123")
// Prints: Alex -> [lives_in] -> Bangkok
```

---

## 📊 Open-Source Competitor Comparison

Why pay recurring server bills or manage Docker containers when Apple Silicon can run everything on-device for free?

| Capability / Architecture Dimension | SynapseMemory  | Mem0 (Cloud / OSS) | Supermemory | Letta (MemGPT) | Zep |
|---|:---:|:---:|:---:|:---:|:---:|
| **Zero Hosting Cost ($0.00 / Zero Server Bills)** | ✅ Yes ($0.00) | ❌ Paid / Docker | ⚠️ Paid Cloud | ⚠️ Self-Hosted | ❌ Subscription |
| **100% On-Device Local Privacy** | ✅ Complete | ⚠️ Python / Cloud | ❌ Cloud Only | ⚠️ Local Python | ❌ Cloud Only |
| **Hardware-Accelerated SIMD Vector Search** | ✅ Apple Accelerate (`vDSP`) | ❌ Qdrant / Chroma | ❌ Cloud Index | ❌ Postgres / Chroma | ❌ Cloud Index |
| **Full-Text BM25 Keyword Search** | ✅ SQLite FTS5 Virtual Tables | ⚠️ SQLite / Postgres | ⚠️ Keyword Search | ⚠️ SQL Search | ⚠️ Hybrid Cloud |
| **Hybrid Search Fusion (Dense + Sparse + Decay)** | ✅ Vector + BM25 + Time Decay | ⚠️ Hybrid RRF | ❌ Vector Only | ❌ Vector Only | ⚠️ Hybrid Cloud |
| **Knowledge Graph Memory (Entity Triples)** | ✅ Local SQLite Triples | ✅ Graphiti / NetworkX | ❌ Not Supported | ⚠️ Structured Tools | ✅ Temporal Graphiti |
| **Bi-Temporal Fact Superseding (`validFrom/validTo`)** | ✅ Built-in | ✅ Built-in | ❌ Not Supported | ❌ Not Supported | ⚠️ Temporal Logs |
| **Document & Bookmark Ingestion (Chunk & Auto-Tag)** | ✅ Built-in (`ingest()`) | ⚠️ Custom Loaders | ✅ Built-in | ⚠️ Attachments | ❌ Not Supported |
| **Hierarchical Working Memory Blocks (Persona State)** | ✅ Built-in (`coreBlock`) | ❌ Not Supported | ❌ Not Supported | ✅ Core Architecture | ❌ Not Supported |
| **Chronological Recall Memory Log & Playback** | ✅ Built-in (`recall()`) | ❌ Not Supported | ❌ Not Supported | ✅ Built-in | ⚠️ Dialog Log |
| **Rolling Dialogue Summarization & Context Compression** | ✅ Built-in (`summarize()`) | ❌ Not Supported | ❌ Not Supported | ⚠️ Tool Calls | ✅ Core Architecture |
| **Multi-Device Private Sync (Zero Third-Party DB)** | ✅ Apple CloudKit iCloud | ❌ Cloud DB Cluster | ⚠️ Web Sync | ❌ Server Sync | ❌ Cloud Backend |
| **On-Device Apple Foundation Models & Guided Generation** | ✅ Native Zero-Config | ❌ Cloud API / Ollama | ❌ Cloud API | ❌ Cloud API / Ollama | ❌ Cloud API |
| **Local Offline LLM Support (Ollama on Mac)** | ✅ Built-in (`OllamaProvider`) | ⚠️ Local Python | ❌ Cloud Only | ⚠️ Local vLLM | ❌ Cloud Only |
| **Apple Native Ecosystem (CoreSpotlight & Siri AppIntents)**| ✅ Native iOS/macOS | ❌ Not Supported | ❌ Not Supported | ❌ Not Supported | ❌ Not Supported |

> For a detailed architectural deep dive, see **[Competitor Comparison & Analysis](docs/architecture/competitor-comparison.md)**.

---

## 📚 Granular Documentation Catalog (`docs/`)

Explore complete, granular documentation inside the [`docs/`](docs/README.md) directory:

| Section | Topic & Documentation Link | Description |
|---|---|---|
| 🚀 **Getting Started** | **[Quick Start Guide](docs/getting-started/quick-start.md)** | Installation via SPM, requirements, and basic usage. |
| | **[Configuration Reference](docs/getting-started/configuration.md)** | `SynapseConfig` options, vector dimensions, and storage settings. |
| 🏛️ **Architecture** | **[System Architecture](docs/architecture/overview.md)** | Multi-tiered memory engine, actor isolation, and subsystem design. |
| | **[Competitor Matrix](docs/architecture/competitor-comparison.md)** | Architectural comparison vs Mem0, Supermemory, Letta, and Zep. |
| 📖 **Guides** | **[Conversational Memory](docs/guides/conversational-memory.md)** | State machine (`ADD`, `UPDATE`, `DELETE`), bi-temporal fact superseding. |
| | **[Knowledge Graph](docs/guides/knowledge-graph.md)** | Entity triple extraction, SQLite graph store, and graph traversal. |
| | **[Document Ingestion](docs/guides/document-ingestion.md)** | Supermemory-style document/URL ingestion, chunking, and auto-tagging. |
| | **[Hybrid Search Engine](docs/guides/hybrid-search.md)** | Fusion of SIMD vector search (`vDSP`), SQLite FTS5 BM25, and time-decay. |
| | **[CloudKit Private Sync](docs/guides/cloudkit-sync.md)** | Encrypted multi-device sync, delta change tokens, and offline queues. |
| | **[Apple Integrations](docs/guides/apple-integrations.md)** | Spotlight system indexing, Siri AppIntents, and `BGTaskScheduler`. |
| 🛈 **API Reference** | **[SynapseClient API](docs/api-reference/synapse-client.md)** | Complete Swift API reference for `SynapseClient` actor methods. |
| | **[Intelligence Providers](docs/api-reference/intelligence-providers.md)** | Apple Foundation Models, Ollama, OpenAI, and Mock providers. |

---

## 🏗️ Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                       Apple Intelligence Client App                         │
└──────────────────────────────────────┬──────────────────────────────────────┘
                                       │
┌──────────────────────────────────────▼──────────────────────────────────────┐
│                             SynapseClient (Actor)                           │
│ ┌──────────────────────┐ ┌──────────────────────┐ ┌──────────────────────┐ │
│ │ Apple Foundation     │ │ SIMD Vector          │ │ Knowledge Graph      │ │
│ │ Model Extractor      │ │ Search Engine        │ │ Engine (Triples)     │ │
│ ├──────────────────────┤ ├──────────────────────┤ ├──────────────────────┤ │
│ │ Supermemory Ingest   │ │ Letta Hierarchical   │ │ Zep Rolling Dialogue │ │
│ │ & Document Chunker   │ │ Recall Memory Log    │ │ Summarizer Engine    │ │
│ └──────────┬───────────┘ └──────────┬───────────┘ └──────────┬───────────┘ │
└────────────┼────────────────────────┼────────────────────────┼──────────────┘
             │                        │                        │
┌────────────▼────────────────────────▼────────────────────────▼──────────────┐
│                           Core Storage Subsystem                            │
│ ┌─────────────────────────────────────────────────────────────────────────┐ │
│ │ Local Hybrid SQLite FTS5 + Accelerate SIMD Vector Store + Graph Store   │ │
│ └────────────────────────────────────┬────────────────────────────────────┘ │
└──────────────────────────────────────┼──────────────────────────────────────┘
                                       │ CloudKit Delta Sync
┌──────────────────────────────────────▼──────────────────────────────────────┐
│                    Apple CloudKit Private iCloud Database                   │
│ ┌─────────────────────────────────────────────────────────────────────────┐ │
│ │ CKRecordZone: "SynapsePrivateZone"                                      │ │
│ └─────────────────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 🏛️ Open-Source Attribution & Inspiration

- **[Mem0](https://github.com/mem0ai/mem0)**: State machine & bi-temporal fact invalidation.
- **[Supermemory](https://github.com/supermemoryai/supermemory)**: Document chunking & tag extraction.
- **[Letta / MemGPT](https://github.com/letta-ai/letta)**: Tiered working memory & recall logs.
- **[Zep](https://github.com/getzep/zep)**: Rolling dialogue summarization & recency decay.

---

## ⚖️ License

SynapseMemory is licensed under the [MIT License](LICENSE).
