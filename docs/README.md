# SynapseMemory Documentation Hub

Welcome to the official documentation for **SynapseMemory** — the local-first, zero-cost agentic memory framework engineered specifically for Apple Silicon and Apple platforms (iOS 27+, macOS 27+, visionOS 27+, watchOS 20+).

---

## 🗺️ Documentation Directory

Explore the documentation organized by topic below:

### 🚀 Getting Started
- **[Quick Start Guide](getting-started/quick-start.md)**: 30-second setup, installation via Swift Package Manager, and basic usage examples.
- **[Configuration Reference](getting-started/configuration.md)**: Customizing `SynapseConfig`, vector dimensions, SIMD similarity metrics, storage paths, and providers.

### 🏛️ Architecture & Concepts
- **[System Architecture & Design](architecture/overview.md)**: Deep dive into the actor model, memory hierarchy (Working Memory, Recall Logs, Archival Vector, Knowledge Graph), and component interaction topology.
- **[Competitor Comparison & Benchmarks](architecture/competitor-comparison.md)**: Architectural analysis comparing SynapseMemory against Mem0, Supermemory, Letta (MemGPT), and Zep.

### 📖 Feature Guides
- **[Conversational Memory & Extraction](guides/conversational-memory.md)**: State transitions (`ADD`, `UPDATE`, `DELETE`, `NO_CHANGE`), automatic extraction, and bi-temporal fact superseding (`validFrom`/`validTo`).
- **[Knowledge Graph Engine](guides/knowledge-graph.md)**: Entity-relation triple extraction, local SQLite graph store, and graph traversal queries (`getRelations`).
- **[Document & Bookmark Ingestion](guides/document-ingestion.md)**: Supermemory-style URL/Doc ingestion, sliding window semantic chunking, and auto-tagging.
- **[Hybrid Search Engine](guides/hybrid-search.md)**: 3-layer search engine fusing Accelerate SIMD vector search (`vDSP`), SQLite FTS5 BM25 keyword search, and time-decay recency scoring.
- **[CloudKit Multi-Device Sync](guides/cloudkit-sync.md)**: Encrypted private iCloud syncing, custom record zones (`SynapsePrivateZone`), delta tokens, and offline mutation handling.
- **[Apple Ecosystem Integrations](guides/apple-integrations.md)**: System-wide search via `CoreSpotlight`, Siri Shortcuts via `AppIntents`, and background maintenance via `BGTaskScheduler`.

### 🛈 API Reference
- **[SynapseClient API Reference](api-reference/synapse-client.md)**: Complete Swift API reference for `SynapseClient` actor methods and parameters.
- **[Intelligence Providers Reference](api-reference/intelligence-providers.md)**: Documentation for LLM and Embedding provider protocols, including Apple Foundation Models, Ollama, and OpenAI.

---

## 💡 Key Design Principles

1. **Zero Hosting Cost ($0.00)**: Runs 100% locally on Apple Silicon without requiring expensive cloud vector databases or monthly server bills.
2. **Sub-15ms Hardware Acceleration**: Leverages Apple's `Accelerate.framework` (`vDSP`) for SIMD-accelerated vector mathematics on local NPU/GPU hardware.
3. **Multi-Tiered Agentic Memory**: Unites Knowledge Graph Triples (Mem0), Document Ingestion (Supermemory), Working Memory & Recall Logs (Letta/MemGPT), and Rolling Dialogue Compression (Zep).
4. **End-to-End Privacy & Sync**: Synchronizes all user memories across Apple devices via the user's private encrypted Apple CloudKit database.
