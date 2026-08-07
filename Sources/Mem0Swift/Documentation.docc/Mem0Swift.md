# ``Mem0Swift``

A native Swift, local-first AI memory framework uniting the innovations of Mem0, Supermemory, Letta/MemGPT, and Zep for Apple Silicon and Apple CloudKit.

## Overview

Mem0Swift provides persistent long-term memory for Apple Intelligence agentic systems, virtual assistants, and conversational native applications running on modern Apple platforms (**iOS 27.0+**, **macOS 27.0+**, **visionOS 27.0+**, **watchOS 20.0+**).

It automatically extracts structured user facts, preferences, and entity-relationship knowledge graphs using Apple Foundation Models, indexes float array vectors locally using Apple's `Accelerate.framework` (SIMD/vDSP) and SQLite FTS5, ingests documents and bookmarks (Supermemory), provides 3-tier memory management (Letta/MemGPT), dialogue summarization (Zep), and synchronizes memory state privately across user devices using CloudKit without requiring external backend server infrastructure.

## Topics

### Essentials
- <doc:GettingStarted>
- <doc:AppleFoundationModels>
- <doc:GraphMemoryGuide>
- <doc:CompetitorComparison>
- <doc:CloudKitSyncGuide>
- <doc:CustomLLMProvider>

### Client & Configuration
- ``Mem0Client``
- ``Mem0Config``

### Core Data Models & Graphs
- ``MemoryItem``
- ``Entity``
- ``Relation``
- ``GraphTriple``
- ``DocumentItem``
- ``RecallMessage``
- ``ConversationSummary``
- ``MemoryTier``
- ``Message``
- ``MemoryFilter``
- ``SearchResult``
- ``MemoryHistoryItem``
- ``CoreMemoryBlock``

### Core Storage & Search
- ``VectorStore``
- ``GraphStore``
- ``LocalVectorStore``
- ``LocalGraphStore``
- ``VectorMath``

### Intelligence & Reasoning
- ``EmbeddingProvider``
- ``LLMProvider``
- ``MemoryExtractor``
- ``ContentChunker``
- ``DialogueSummarizer``
- ``AppleFoundationModelProvider``
- ``OllamaProvider``
- ``OpenAIProvider``

### CloudKit Synchronization
- ``CloudKitSyncEngine``

### Platform Integrations
- ``CoreSpotlightIndexer``
- ``SearchMemoriesIntent``
- ``AddMemoryIntent``
- ``Mem0BackgroundTaskHandler``
