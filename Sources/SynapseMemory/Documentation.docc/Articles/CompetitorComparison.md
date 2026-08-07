# Competitive Analysis & Architecture Convergence

Compare SynapseMemory against open-source memory frameworks (**Mem0**, **Supermemory**, **Letta/MemGPT**, and **Zep**).

## Overview

Modern agentic AI architectures typically depend on server-hosted microservices (Postgres with `pgvector`, Qdrant, Neo4j, or Redis). This introduces high recurring cloud infrastructure costs, latency, and privacy compliance hurdles.

**SynapseMemory** draws architectural inspiration from the best open-source projects in the memory ecosystem, re-engineered from the ground up as a native Swift 6 framework running **100% on-device on Apple Silicon** with **zero recurring cloud hosting costs**.

---

## 📊 Comprehensive Feature Matrix

| Feature Dimension | Mem0 (Python/Cloud) | Supermemory | Letta / MemGPT | Zep | SynapseMemory (Apple Native) |
|---|---|---|---|---|---|
| **Hosting Cost** | Paid Cloud / Docker Server | Cloud Hosted | Self-Hosted Server | Cloud Subscription | **$0.00 (100% Free & Local)** |
| **Vector Engine** | Qdrant / Chroma | Cloud Index | Postgres / Chroma | Cloud Vector DB | **Apple `Accelerate` SIMD (vDSP)** |
| **Full-Text Search** | SQLite / Postgres | Keyword Search | SQL / SQLite | Semantic/Keyword | **SQLite FTS5 Porter Virtual Tables** |
| **Knowledge Graphs** | Graphiti / NetworkX | Auto-Tagging | Structured Tools | Temporal Graphiti | **[LocalGraphStore](doc:LocalGraphStore) (Entity Triples)** |
| **Document Ingestion** | Custom Loaders | URL & Bookmark Parser | File Attachments | Dialog Summaries | **[ingest()](doc:SynapseClient/ingest) (Chunking & Tagging)** |
| **Tiered Memory** | Single Store | Bookmarks | Working / Recall / Archival | Summary + Episodic | **Hierarchical [MemoryTier](doc:MemoryTier)** |
| **Cross-Device Sync** | Cloud Database Cluster | Web App Sync | Server Synchronization | Cloud Backend | **Apple CloudKit (`SynapsePrivateZone`)** |
| **On-Device LLM** | Ollama (Local Python) | Web API | Local Ollama / vLLM | Cloud API | **Apple Foundation Models + Ollama** |
| **System Integrations** | None | Chrome Extension | REST API | LangChain / SDK | **CoreSpotlight + Siri AppIntents** |

---

## 🏛️ Architectural Attribution & Inspiration

- **Mem0 ([mem0ai/mem0](https://github.com/mem0ai/mem0))**: Pioneered the conversational extraction state machine (`ADD`, `UPDATE`, `DELETE`, `NO_CHANGE`) and bi-temporal fact invalidation.
- **Supermemory ([supermemoryai/supermemory](https://github.com/supermemoryai/supermemory))**: Inspired the document ingestion, URL bookmarking, and automatic semantic tag extraction pipelines.
- **Letta / MemGPT ([letta-ai/letta](https://github.com/letta-ai/letta))**: Inspired the 3-tier memory hierarchy: In-Context Working Memory Blocks, Chronological Recall Logs, and Archival Vector Storage.
- **Zep ([getzep/zep](https://github.com/getzep/zep))**: Inspired the rolling dialogue summarizer and temporal recency decay scoring.
