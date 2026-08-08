# System Architecture & Design

**SynapseMemory** is designed as a local-first, unified memory engine for Apple Silicon devices. It integrates the core breakthroughs of modern AI memory systems (**Mem0**, **Supermemory**, **Letta/MemGPT**, **Zep**) into a single, light-weight native Swift actor.

---

## 🏛️ High-Level System Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                       Apple Intelligence Client App                         │
└──────────────────────────────────────┬──────────────────────────────────────┘
                                       │
┌──────────────────────────────────────▼──────────────────────────────────────┐
│                             SynapseClient (Actor)                           │
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
│ │ CKRecordZone: "SynapsePrivateZone"                                      │ │
│ │  ├── RecordType: "SynapseMemory"                                        │ │
│ │  ├── RecordType: "SynapseEntity"                                        │ │
│ │  ├── RecordType: "SynapseRelation"                                      │ │
│ │  └── RecordType: "SynapseHistory"                                       │ │
│ └─────────────────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 🧠 Memory Tiers

SynapseMemory implements a multi-tiered memory architecture inspired by human cognition and Letta/MemGPT:

```
+-------------------------------------------------------------------+
| 1. Working Memory (In-Context Core Persona & System Prompt)        |
+-------------------------------------------------------------------+
| 2. Recall Memory (Chronological Dialogue History & Event Log)      |
+-------------------------------------------------------------------+
| 3. Archival Memory (Dense Vectors + BM25 Full-Text Search)         |
+-------------------------------------------------------------------+
| 4. Knowledge Graph (Subject -> Predicate -> Object Triples)        |
+-------------------------------------------------------------------+
```

### 1. Working Memory (`coreBlock`)
- Holds dynamic agent persona state, user preferences, and real-time instructions.
- Stored as key-value text blocks that are directly injected into prompt contexts.

### 2. Recall Memory Log
- Stores chronological message turns (`Message(role, content, timestamp)`).
- Supports full dialogue playback and contextual reconstruction.

### 3. Archival Vector & Keyword Storage
- Extracts semantic facts and stores high-dimensional vector embeddings alongside raw text.
- Indexed with SQLite FTS5 virtual tables for full-text search capability.

### 4. Knowledge Graph Triples
- Represents relational knowledge as directed edges `(Subject, Predicate, Object)`.
- Allows graph traversal (e.g. `Alex -> lives_in -> Bangkok`).

---

## 🔒 Storage Subsystem Details

### Local Vector & Graph Storage (`LocalVectorStore`, `LocalGraphStore`)
- Built on top of `SQLite3` with WAL (Write-Ahead Logging) enabled for maximum throughput.
- Hardware-accelerated vector similarity math powered by Apple `Accelerate.framework` (`vDSP_dotpr`, `vDSP_vpyth`).

### Multi-Tenant Data Scoping
All memory items, relations, and recall logs support multi-tenant filtering:
- `userId`: Scopes data to a specific user account.
- `agentId`: Scopes data to a specific agent instance.
- `runId`: Scopes data to a specific session or task execution.

---

## 🔄 CloudKit Sync Subsystem (`CloudKitSyncEngine`)

- **Zero Third-Party Cloud Dependencies**: Uses the user's personal encrypted iCloud container via Apple's native CloudKit framework.
- **Custom Record Zone**: Isolates all memory records in `SynapsePrivateZone`.
- **Incremental Delta Tokens**: Only fetches updated `CKRecord` modifications using `CKFetchRecordZoneChangesOperation`.
- **Automatic Retries & Error Handling**: Handles network drops, quota limits, and conflict resolutions natively.
