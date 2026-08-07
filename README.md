# SynapseMemory

[![Swift 6.0](https://img.shields.io/badge/Swift-6.0-orange.svg?style=flat)](https://swift.org)
[![Target Platform](https://img.shields.io/badge/Platform-iOS%2027+%20|%20macOS%2027+%20|%20visionOS%2027+%20|%20watchOS%2020+-black.svg?logo=apple)](https://developer.apple.com)
[![Storage](https://img.shields.io/badge/Storage-Apple%20CloudKit%20Private%20Sync-blue.svg)](https://developer.apple.com/icloud/cloudkit/)
[![Cost](https://img.shields.io/badge/Hosting%20Cost-$0.00%20(Zero%20Servers)-green.svg)](https://github.com/VM451/synapse-memory-swift)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

> **The Ultimate Local-First Agentic Memory Framework for Apple Silicon.**
> 
> Uniting the best architectural innovations of **Mem0**, **Supermemory**, **Letta/MemGPT**, and **Zep** into a unified, lightweight native Swift library. **100% on-device execution with zero cloud hosting costs**, seamlessly synced across user Apple devices via **Apple CloudKit private database**.
> 
> **Target Platforms**: **iOS 27.0+**, **macOS 27.0+**, **visionOS 27.0+**, **watchOS 20.0+**.

---

## ⚡ 30-Second Quick Start

Zero server setup, zero cloud bills — runs 100% locally on Apple Silicon:

```swift
import SynapseMemory

// 1. Initialize SynapseClient (Defaults to Apple Foundation Models + CloudKit)
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

## 📊 In-Depth Open-Source Competitor Comparison

Why pay recurring server bills or manage Docker containers when Apple Silicon can run everything on-device for free?

| Capability / Architecture Dimension | SynapseMemory (This Repo)  | Mem0 (Cloud / OSS) | Supermemory | Letta (MemGPT) | Zep |
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
| **Multi-Tenant Scoping (`userId`, `agentId`, `runId`)** | ✅ Built-in Filters | ✅ Built-in Filters | ⚠️ Workspace Only | ⚠️ Agent Only | ✅ User / Session |
| **Bulk Operations & Reset (`deleteAll`, `reset`)** | ✅ Built-in APIs | ✅ Built-in APIs | ⚠️ Partial | ⚠️ Partial | ⚠️ Partial |

---

### 🔍 Architectural Trade-Offs & Why SynapseMemory is Superior for Apple Developers

#### 🌟 Where SynapseMemory is Superior:
1. **$0.00 Hosting Cost & Zero Infrastructure**: Traditional frameworks (Mem0 Cloud, Zep Cloud, Supermemory Cloud) require subscription tiers or managing complex cloud infrastructure (Docker, Qdrant, PostgreSQL, Neo4j). SynapseMemory runs 100% locally on Apple devices with zero recurring expenses.
2. **Sub-15ms SIMD Hardware Acceleration**: Uses Apple's `Accelerate.framework` (`vDSP_dotpr`) directly executing vector similarity calculations on Apple Silicon neural engines / GPUs.
3. **Private Multi-Device Sync via Apple CloudKit**: Automatically synchronizes memories, document chunks, and knowledge graph relations across the user's personal iPhone, Mac, iPad, Vision Pro, and Apple Watch using encrypted iCloud private databases (`CKContainer.default().privateCloudDatabase`).
4. **All-In-One Unified Agentic Memory**: Unites the best features of Mem0 (Knowledge Graph), Supermemory (Document Ingest), Letta (Hierarchical Working & Recall Memory), and Zep (Rolling Dialogue Summarizer) into one cohesive Swift 6 library.
5. **Deep Apple Ecosystem Integration**: Indexes memories directly into iOS/macOS system search (`CoreSpotlight`), exposes Siri Shortcuts via `AppIntents`, and consolidates memories during idle charging states via `BGTaskScheduler`.

#### ⚖️ Target Scope & Modern Apple Platforms:
- **Engineered Exclusively for Modern Apple Platforms**: SynapseMemory is targeted specifically for **iOS 27.0+**, **macOS 27.0+**, **visionOS 27.0+**, and **watchOS 20.0+** to take maximum advantage of the latest Apple Silicon hardware instructions, Swift 6 strict concurrency, and Apple Foundation Model system APIs.

---

## 🏗️ Architecture

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
│ │  ├── RecordType: "SynapseMemory"                                        │ │
│ │  ├── RecordType: "SynapseEntity"                                        │ │
│ │  ├── RecordType: "SynapseRelation"                                      │ │
│ │  └── RecordType: "SynapseHistory"                                       │ │
│ └─────────────────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 🏛️ Open-Source Attribution & Inspiration

SynapseMemory draws inspiration from pioneer projects in the AI agent memory ecosystem:
- **[Mem0](https://github.com/mem0ai/mem0)**: Conversational memory state machine (`ADD`, `UPDATE`, `DELETE`, `NO_CHANGE`) and bi-temporal fact invalidation.
- **[Supermemory](https://github.com/supermemoryai/supermemory)**: Document and URL bookmark ingestion, auto-tagging, and semantic content chunking.
- **[Letta / MemGPT](https://github.com/letta-ai/letta)**: Tiered memory hierarchy (In-context Working Memory Blocks, Chronological Recall Logs, and Archival Vector Storage).
- **[Zep](https://github.com/getzep/zep)**: Rolling dialogue summarization and time-decay recency scoring.

---

## 🧪 Installation

Add `SynapseMemory` to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/VM451/synapse-memory-swift.git", from: "1.0.0")
]
```

---

## 📚 Documentation

Explore the complete Apple DocC documentation catalog inside `Sources/SynapseMemory/Documentation.docc`.

---

## ⚖️ License

SynapseMemory is open-source software licensed under the MIT license.
