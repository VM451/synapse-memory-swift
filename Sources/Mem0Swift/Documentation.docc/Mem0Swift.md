# ``Mem0Swift``

A native Swift, local-first AI memory framework purpose-built for Apple Foundation Models and Apple CloudKit.

## Overview

Mem0Swift provides persistent long-term memory for Apple Intelligence agentic systems, virtual assistants, and conversational native applications running on Apple platforms (iOS 17+, macOS 14+, visionOS 1+, watchOS 10+).

It automatically extracts structured user facts and preferences using Apple Foundation Models, indexes float array vectors locally using Apple's `Accelerate.framework` (SIMD/vDSP) and SQLite FTS5, and synchronizes memory state privately across user devices using CloudKit without requiring external backend server infrastructure.

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

## Topics

### Essentials
- <doc:GettingStarted>
- <doc:AppleFoundationModels>
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
- ``AppleFoundationModelProvider``
- ``OpenAIProvider``

### CloudKit Synchronization
- ``CloudKitSyncEngine``

### Platform Integrations
- ``CoreSpotlightIndexer``
- ``SearchMemoriesIntent``
- ``AddMemoryIntent``
- ``Mem0BackgroundTaskHandler``
