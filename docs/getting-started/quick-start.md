# Quick Start Guide

This guide will get you up and running with **SynapseMemory** in under 5 minutes.

---

## 📋 Requirements

- **Swift**: 6.0 or higher
- **Platforms**:
  - iOS 27.0+
  - macOS 27.0+
  - visionOS 27.0+
  - watchOS 20.0+
- **Hardware**: Apple Silicon (M1/M2/M3/M4 or A17 Pro/A18+) recommended for optimal SIMD hardware acceleration.

---

## 📦 Installation

Add `SynapseMemory` to your project using **Swift Package Manager**.

### Using Xcode
1. Open your project in Xcode.
2. Go to **File > Add Package Dependencies...**
3. Enter repository URL: `https://github.com/VM451/synapse-memory-swift.git`
4. Select version `1.0.0` or main branch and add to your app target.

### Using `Package.swift`
Add `SynapseMemory` to the `dependencies` array of your `Package.swift`:

```swift
// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "MyAgentApp",
    platforms: [
        .macOS(.v15), // Or modern OS target
        .iOS(.v18)
    ],
    dependencies: [
        .package(url: "https://github.com/VM451/synapse-memory-swift.git", from: "1.0.0")
    ],
    targets: [
        .target(
            name: "MyAgentApp",
            dependencies: [
                .product(name: "SynapseMemory", package: "synapse-memory-swift")
            ]
        )
    ]
)
```

---

## ⚡ 30-Second Code Example

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
for triple in triples {
    print("Triple: \(triple.subject) -> [\(triple.predicate)] -> \(triple.object)")
}
```

---

## 🔒 CloudKit Entitlements Setup

If enabling automatic iCloud synchronization, make sure to add the **iCloud Capability** to your App Target in Xcode:

1. Select your target in Xcode -> **Signing & Capabilities**.
2. Click **+ Capability** and select **iCloud**.
3. Check **CloudKit**.
4. Create or select a CloudKit container (e.g. `iCloud.com.yourcompany.yourapp`).

For details on customizing CloudKit settings, see [CloudKit Multi-Device Sync Guide](../guides/cloudkit-sync.md).
