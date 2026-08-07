# Mem0Swift

[![Swift 6.0](https://img.shields.io/badge/Swift-6.0-orange.svg?style=flat)](https://swift.org)
[![Target Platform](https://img.shields.io/badge/Platform-Apple%20Foundation%20Models-black.svg?logo=apple)](https://developer.apple.com)
[![CloudKit Sync](https://img.shields.io/badge/Storage-Apple%20CloudKit-blue.svg)](https://developer.apple.com/icloud/cloudkit/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

> **Native Swift AI Memory Library Purpose-Built Specifically for Apple Foundation Models & CloudKit.**

**Mem0Swift** is a lightweight, local-first memory framework engineered specifically for **Apple Foundation Models**, **Apple Intelligence agentic systems**, and **Apple CloudKit private database storage**. It automatically extracts, organizes, deduplicates, and retrieves user/agent memories across conversation turns running directly on Apple Silicon.

---

## ⚡ 30-Second Quick Start

Zero configuration required — defaults 100% to **Apple Foundation Models** and **Apple CloudKit**:

```swift
import Mem0Swift

// 1. Initialize Mem0Client (Defaults to Apple Foundation Models + CloudKit)
let mem0 = try await Mem0Client(config: Mem0Config())

// 2. Extract facts from conversation turns using Apple Foundation Model
let messages = [
    Message(role: .user, content: "Hi, I live in Bangkok and prefer dark mode UI."),
    Message(role: .assistant, content: "Got it! I will remember that you live in Bangkok and prefer dark mode UI.")
]
try await mem0.add(messages: messages, userId: "alex_123")

// 3. Query relevant user memory context for Apple Intelligence prompt insertion
let results = try await mem0.search(query: "Where does the user live?", userId: "alex_123")
for item in results {
    print("Found Memory: \(item.item.memory) (Score: \(item.score))")
}
```

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
│ │ Apple Foundation     │ │ SIMD Vector          │ │ CloudKit Delta       │ │
│ │ Model Extractor      │ │ Search Engine        │ │ Sync Controller      │ │
│ └──────────┬───────────┘ └──────────┬───────────┘ └──────────┬───────────┘ │
└────────────┼────────────────────────┼────────────────────────┼──────────────┘
             │                        │                        │
┌────────────▼────────────────────────▼────────────────────────▼──────────────┐
│                           Core Storage Subsystem                            │
│ ┌─────────────────────────────────────────────────────────────────────────┐ │
│ │ Local Hybrid Storage Engine (SQLite FTS5 + Accelerate SIMD Vector Index)│ │
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

## 🌟 Designed Exclusively for Apple Native Apps

- **Apple Foundation Models & Guided Generation**: Purpose-built driver for Apple Foundation Models, `@Tool` guided generation schemas, and on-device `NLEmbedding`.
- **Zero Third-Party Backend Infrastructure**: Uses the end user's personal Apple CloudKit account (`.privateCloudDatabase`) without requiring Postgres/Qdrant/Pinecone server clusters.
- **Apple Silicon Hardware Accelerated**: Sub-15ms SIMD vector similarity search using Apple's `Accelerate.framework` (`vDSP_dotpr`).
- **Bi-Temporal Knowledge Progression**: Tracks `validFrom`, `validTo`, and `supersededById` to prevent memory fact pollution over time.
- **Apple Platform Integration**: Native CoreSpotlight system search indexing, Siri / Shortcuts `AppIntents`, and `BGTaskScheduler` background memory consolidation.

---

## 🧪 Installation

In your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/VM451/mem0-swift.git", from: "1.0.0")
]
```

---

## 📚 Documentation

Complete Apple DocC documentation catalog is included under `Sources/Mem0Swift/Documentation.docc`. Generate docs in Xcode via **Product** -> **Build Documentation**.

---

## ⚖️ License

Mem0Swift is available under the MIT license. See [LICENSE](LICENSE) for details.
