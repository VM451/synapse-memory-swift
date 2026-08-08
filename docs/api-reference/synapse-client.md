# SynapseClient API Reference

`SynapseClient` is the primary entry point for interacting with SynapseMemory. It is implemented as a Swift **Actor** (`public actor SynapseClient`) to guarantee strict concurrency thread safety.

---

## 🔑 Initialization

### `init(config: SynapseConfig)`

Initializes a new `SynapseClient` instance with the specified configuration.

```swift
public init(config: SynapseConfig = SynapseConfig()) async throws
```

- **Parameters**:
  - `config`: A `SynapseConfig` struct specifying database paths, memory thresholds, providers, and sync options.

---

## 📥 Ingestion & Extraction APIs

### `add(messages:userId:agentId:runId:metadata:)`

Extracts memories, knowledge graph triples, and recall logs from conversational message turns.

```swift
public func add(
    messages: [Message],
    userId: String,
    agentId: String? = nil,
    runId: String? = nil,
    metadata: [String: String]? = nil
) async throws
```

- **Parameters**:
  - `messages`: Array of `Message` turns (`.user`, `.assistant`, `.system`).
  - `userId`: Unique ID of the user.
  - `agentId`: Optional agent scope ID.
  - `runId`: Optional session or run scope ID.
  - `metadata`: Optional metadata dictionary.

---

### `ingest(content:title:userId:agentId:tags:sourceURL:)`

Ingests unstructured documents or web bookmarks using Supermemory-style sliding window chunking and auto-tagging.

```swift
public func ingest(
    content: String,
    title: String? = nil,
    userId: String,
    agentId: String? = nil,
    tags: [String]? = nil,
    sourceURL: URL? = nil
) async throws
```

---

## 🔍 Retrieval & Search APIs

### `search(query:userId:agentId:runId:filters:limit:)`

Executes a 3-layer hybrid search query fusing SIMD vector similarity, BM25 full-text keyword matching, and time-decay recency scoring.

```swift
public func search(
    query: String,
    userId: String,
    agentId: String? = nil,
    runId: String? = nil,
    filters: MemoryFilter? = nil,
    limit: Int = 10
) async throws -> [SearchResult]
```

- **Returns**: Array of `SearchResult` instances containing matching `MemoryItem` records and composite scores.

---

### `getRelations(userId:agentId:)`

Retrieves directed entity-relation-entity triples stored in the local knowledge graph.

```swift
public func getRelations(
    userId: String,
    agentId: String? = nil
) async throws -> [Relation]
```

---

### `recall(userId:limit:)`

Retrieves the chronological recall memory dialogue log for a user.

```swift
public func recall(
    userId: String,
    limit: Int = 50
) async throws -> [MemoryHistoryItem]
```

---

## 📝 Working Memory & Summarization APIs

### `updateCoreMemoryBlock(userId:block:)`

Updates the working memory persona block (`coreBlock`) for a user.

```swift
public func updateCoreMemoryBlock(
    userId: String,
    block: CoreMemoryBlock
) async throws
```

---

### `summarize(userId:)`

Triggers Zep-style rolling dialogue summarization to compress old conversation turns.

```swift
public func summarize(userId: String) async throws -> ConversationSummary
```

---

## 🗑️ Deletion & Reset APIs

### `delete(memoryId:)`

Deletes a specific memory item by ID.

```swift
public func delete(memoryId: String) async throws
```

---

### `deleteAll(userId:)`

Deletes all memory items, graph relations, and recall logs for a specific user ID.

```swift
public func deleteAll(userId: String) async throws
```

---

### `reset()`

Wipes all local SQLite database tables and resets storage state completely.

```swift
public func reset() async throws
```
