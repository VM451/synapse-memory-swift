# Mem0Swift

[![Swift 6.0](https://img.shields.io/badge/Swift-6.0-orange.svg?style=flat)](https://swift.org)
[![Platforms](https://img.shields.io/badge/Platforms-iOS%2017%2B%20%7C%20macOS%2014%2B%20%7C%20visionOS%201%2B%20%7C%20watchOS%2010%2B-blue.svg)](https://developer.apple.com)
[![CloudKit Sync](https://img.shields.io/badge/CloudKit-Private%20Sync-green.svg)](https://developer.apple.com/icloud/cloudkit/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

> Local-first, bi-temporal AI memory framework for Apple platforms with native CloudKit synchronization.

Inspired by [mem0](https://github.com/mem0ai/mem0), **Mem0Swift** gives AI agents, assistants, and Apple native applications intelligent long-term memory across conversation turns without requiring external server infrastructure (Postgres/Qdrant/Pinecone).

---

## ⚡ 30-Second Quick Start

```swift
import Mem0Swift

// 1. Initialize Configuration & Client
let config = Mem0Config(
    llmProvider: OpenAIProvider(apiKey: "sk-..."),
    embeddingProvider: AppleFoundationModelProvider(),
    enableAutoSync: true
)
let mem0 = try await Mem0Client(config: config)

// 2. Extract facts from conversation turns
let messages = [
    Message(role: .user, content: "Hi, I live in Bangkok and prefer dark mode."),
    Message(role: .assistant, content: "Got it! I will remember that you live in Bangkok and love dark mode.")
]
try await mem0.add(messages: messages, userId: "alex_123")

// 3. Search relevant user memories
let results = try await mem0.search(query: "Where does the user live?", userId: "alex_123")
for item in results {
    print("Found Memory: \(item.item.memory) (Score: \(item.score))")
}
```

---

## 🏗️ Architecture Flow

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                            Mem0Swift Client App                             │
└──────────────────────────────────────┬──────────────────────────────────────┘
                                       │
┌──────────────────────────────────────▼──────────────────────────────────────┐
│                              Mem0Client (Actor)                             │
│ ┌──────────────────────┐ ┌──────────────────────┐ ┌──────────────────────┐ │
│ │  Memory Extractor    │ │  Retrieval Engine    │ │ Sync Controller      │ │
│ └──────────┬───────────┘ └──────────┬───────────┘ └──────────┬───────────┘ │
└────────────┼────────────────────────┼────────────────────────┼──────────────┘
             │                        │                        │
┌────────────▼────────────────────────▼────────────────────────▼──────────────┐
│                           Core Storage Subsystem                            │
│ ┌─────────────────────────────────────────────────────────────────────────┐ │
│ │ Local Hybrid Storage Engine (SQLite FTS5 + Accelerate vDSP Index)       │ │
│ └────────────────────────────────────┬────────────────────────────────────┘ │
└──────────────────────────────────────┼──────────────────────────────────────┘
                                       │ CloudKit Engine
┌──────────────────────────────────────▼──────────────────────────────────────┐
│                       Apple CloudKit Private Database                       │
│ ┌─────────────────────────────────────────────────────────────────────────┐ │
│ │ CKRecordZone: "Mem0PrivateZone"                                         │ │
│ │  ├── RecordType: "Mem0Memory"                                           │ │
│ │  └── RecordType: "Mem0History"                                          │ │
│ └─────────────────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 🌟 Key Features Matrix

- [x] **Sub-15ms Local Vector Retrieval**: Accelerated via Apple's `Accelerate.framework` (SIMD/vDSP).
- [x] **Hybrid Vector + FTS5 Search**: Blends dense cosine similarity vectors with SQLite BM25 full-text keyword ranking.
- [x] **Zero-Backend CloudKit Sync**: Multi-device state synchronization via private `CKRecordZone`.
- [x] **On-Device Foundation Models**: Plug-and-play support for Apple `NaturalLanguage` (`NLEmbedding`), CoreML, or remote providers (OpenAI, Ollama).
- [x] **Bi-Temporal Fact Progression**: Tracks `validFrom`, `validTo`, and `supersededById` to avoid memory pollution.
- [x] **Letta / MemGPT Core Memory**: Editable working memory blocks exposed as agentic tools.
- [x] **Apple System Native**: CoreSpotlight system search indexing, Siri AppIntents, and BGTaskScheduler consolidation.

---

## 🧪 Installation

In your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/mem0ai/mem0-swift.git", from: "1.0.0")
]
```

---

## 📚 Documentation

Complete Apple DocC documentation catalog is included under `Sources/Mem0Swift/Documentation.docc`. Generate docs locally in Xcode via **Product** -> **Build Documentation**.

---

## ⚖️ License

Mem0Swift is available under the MIT license. See [LICENSE](LICENSE) for details.
