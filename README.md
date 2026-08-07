# Mem0Swift

[![Swift 6.0](https://img.shields.io/badge/Swift-6.0-orange.svg?style=flat)](https://swift.org)
[![Target Platform](https://img.shields.io/badge/Platform-iOS%2017+%20|%20macOS%2014+%20|%20visionOS%201+-black.svg?logo=apple)](https://developer.apple.com)
[![Storage](https://img.shields.io/badge/Storage-Apple%20CloudKit%20Private%20Sync-blue.svg)](https://developer.apple.com/icloud/cloudkit/)
[![Cost](https://img.shields.io/badge/Hosting%20Cost-$0.00%20(Zero%20Servers)-green.svg)](https://github.com/VM451/mem0-swift)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

> **The Ultimate Local-First Agentic Memory Framework for Apple Silicon.**
> 
> Uniting the best architectural innovations of **Mem0**, **Supermemory**, **Letta/MemGPT**, and **Zep** into a unified, lightweight native Swift library. **100% on-device execution with zero cloud hosting costs**, seamlessly synced across user Apple devices via **Apple CloudKit private database**.

---

## ⚡ 30-Second Quick Start

Zero server setup, zero cloud bills — runs 100% locally on Apple Silicon:

```swift
import Mem0Swift

// 1. Initialize Mem0Client (Defaults to Apple Foundation Models + CloudKit)
let mem0 = try await Mem0Client(config: Mem0Config())

// 2. Add conversational turns (Extracts memories, knowledge graph triples & recall logs)
let messages = [
    Message(role: .user, content: "Hi! I am Alex, I live in Bangkok, and I build native Swift apps."),
    Message(role: .assistant, content: "Great to meet you Alex! I will remember you live in Bangkok.")
]
try await mem0.add(messages: messages, userId: "alex_123")

// 3. Ingest documents and web bookmarks with auto-tagging (Supermemory feature)
try await mem0.ingest(
    content: "Apple Intelligence combines generative models with on-device personal context...",
    title: "Apple Intelligence Notes",
    userId: "alex_123",
    tags: ["apple", "ai", "privacy"]
)

// 4. Hybrid Search (Accelerate SIMD + SQLite FTS5 + Time-Decay)
let results = try await mem0.search(query: "Where does Alex live?", userId: "alex_123")
for item in results {
    print("Found Memory: \(item.item.memory) (Score: \(item.score))")
}

// 5. Query Knowledge Graph Triples (Mem0 & Graphiti feature)
let triples = try await mem0.getRelations(userId: "alex_123")
// Prints: Alex -> [lives_in] -> Bangkok
```

---

## 🏆 Competitor Analysis & Feature Matrix

Why pay recurring server bills or manage Docker containers when Apple Silicon can run everything on-device for free?

| Feature Dimension | Mem0 (Cloud/Python) | Supermemory | Letta / MemGPT | Zep | Mem0Swift (Apple Native) |
|---|---|---|---|---|---|
| **Monthly Hosting Cost** | $$ / Monthly Server | $$ Cloud Plan | Server Costs | Subscription | **$0.00 (Zero Recurring Costs)** |
| **Vector Search Engine** | Qdrant / Chroma | Cloud Index | Postgres / Chroma | Cloud DB | **Apple `Accelerate` SIMD (`vDSP`)** |
| **Full-Text BM25 Search** | SQLite / Postgres | Keyword Search | SQL / SQLite | Semantic/Keyword | **Native SQLite FTS5 Virtual Tables** |
| **Knowledge Graph Memory** | Graphiti / NetworkX | Auto-Tagging | Structured Tools | Temporal Graphiti | **[LocalGraphStore](doc:LocalGraphStore) (Entity Triples)** |
| **Document Ingestion** | Custom Loaders | URL & Bookmarks | File Attachments | Dialog Summaries | **[ingest()](doc:Mem0Client/ingest) (Chunking & Tagging)** |
| **Hierarchical Memory** | Single Store | Bookmarks | Working / Recall / Archival | Summary + Episodic | **Hierarchical [MemoryTier](doc:MemoryTier)** |
| **Cross-Device Sync** | Cloud DB Server | Web App Sync | Server Sync | Cloud Backend | **Apple CloudKit (`Mem0PrivateZone`)** |
| **On-Device LLM** | Ollama (Python) | Web API | Local Ollama / vLLM | Cloud API | **Apple Foundation Models + Ollama** |
| **Apple Platform Native** | ❌ No | ❌ No | ❌ No | ❌ No | **CoreSpotlight + Siri AppIntents** |

---

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                       Apple Intelligence Client App                         │
└──────────────────────────────────────┬──────────────────────────────────────┘
                                       │
┌──────────────────────────────────────▼──────────────────────────────────────┐
│                              Mem0Client (Actor)                             │
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
│ │ CKRecordZone: "Mem0PrivateZone"                                         │ │
│ │  ├── RecordType: "Mem0Memory"                                           │ │
│ │  ├── RecordType: "Mem0Entity"                                           │ │
│ │  ├── RecordType: "Mem0Relation"                                         │ │
│ │  └── RecordType: "Mem0History"                                          │ │
│ └─────────────────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 🏛️ Open-Source Attribution & Inspiration

Mem0Swift draws inspiration from pioneer projects in the AI agent memory ecosystem:
- **[Mem0](https://github.com/mem0ai/mem0)**: Conversational memory state machine (`ADD`, `UPDATE`, `DELETE`, `NO_CHANGE`) and bi-temporal fact invalidation.
- **[Supermemory](https://github.com/supermemoryai/supermemory)**: Document and URL bookmark ingestion, auto-tagging, and semantic content chunking.
- **[Letta / MemGPT](https://github.com/letta-ai/letta)**: Tiered memory hierarchy (In-context Working Memory Blocks, Chronological Recall Logs, and Archival Vector Storage).
- **[Zep](https://github.com/getzep/zep)**: Rolling dialogue summarization and time-decay recency scoring.

---

## 🧪 Installation

Add `Mem0Swift` to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/VM451/mem0-swift.git", from: "1.0.0")
]
```

---

## 📚 Documentation

Explore the complete Apple DocC documentation catalog inside `Sources/Mem0Swift/Documentation.docc`.

---

## ⚖️ License

Mem0Swift is open-source software licensed under the MIT license.
