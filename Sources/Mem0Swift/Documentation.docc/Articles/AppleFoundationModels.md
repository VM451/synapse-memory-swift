# Apple Foundation Models & Agentic Systems Integration

Learn how Mem0Swift is purpose-built to provide native persistent memory exclusively for Apple Intelligence, Apple Foundation Models, and CloudKit.

## Overview

Mem0Swift is designed specifically for Apple native applications. Rather than requiring heavy Python servers or external vector databases (Qdrant, Pinecone, Postgres), Mem0Swift pairs directly with **Apple Foundation Models** and **Apple CloudKit**.

### Key Integration Highlights

- **On-Device Foundation Models & Guided Generation**: Utilizes Apple Silicon hardware acceleration (`Accelerate.framework` SIMD / vDSP) for vector operations and JSON guided generation schema parsing.
- **Zero Third-Party Backend**: Syncs memory items across user Apple devices (iOS, macOS, visionOS, watchOS) using `CKContainer.default().privateCloudDatabase`.
- **System Native Integration**: Integrates directly into Apple system search (`CSSearchableIndex`), Siri/Shortcuts (`AppIntents`), and background consolidation (`BGTaskScheduler`).

```swift
import Mem0Swift

// Zero-configuration: defaults to Apple Foundation Models + CloudKit
let mem0 = try await Mem0Client(config: Mem0Config())

// Store conversational facts extracted via Apple Foundation Model
try await mem0.add(memory: "User prefers dark mode UI and resides in Bangkok", userId: "user_bkk")

// Search relevant memory context for Apple Intelligence prompt construction
let results = try await mem0.search(query: "User preferences", userId: "user_bkk")
```
