# ``Mem0Swift``

A native Swift, local-first AI memory framework with Apple CloudKit synchronization.

## Overview

Mem0Swift provides persistent long-term memory for AI agents, virtual assistants, and conversational apps running on Apple platforms (iOS 17+, macOS 14+, visionOS 1+, watchOS 10+).

It automatically extracts structured user facts and preferences from conversation turns, indexes float array vectors locally using Apple's `Accelerate.framework` (SIMD/vDSP) and SQLite FTS5, and synchronizes memory state privately across user devices using CloudKit without requiring external vector databases.

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

## Topics

### Essentials
- <doc:GettingStarted>
- <doc:CloudKitSyncGuide>
- <doc:CustomLLMProvider>

### Client & Configuration
- ``Mem0Client``
- ``Mem0Config``

### Core Data Models
- ``MemoryItem``
- ``Message``
- ``MemoryFilter``
- ``SearchResult``
- ``MemoryHistoryItem``
- ``CoreMemoryBlock``

### Core Storage & Search
- ``VectorStore``
- ``LocalVectorStore``
- ``VectorMath``

### Intelligence & Reasoning
- ``EmbeddingProvider``
- ``LLMProvider``
- ``MemoryExtractor``
- ``OpenAIProvider``
- ``AppleFoundationModelProvider``

### CloudKit Synchronization
- ``CloudKitSyncEngine``

### Platform Integrations
- ``CoreSpotlightIndexer``
- ``SearchMemoriesIntent``
- ``AddMemoryIntent``
- ``Mem0BackgroundTaskHandler``
