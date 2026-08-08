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

### `ingestDocument(fileURL:loader:tags:userId:metadata:)` ⭐ New

Ingests a local file through the full RAG pipeline: loader auto-detection → chunking → embedding → `KnowledgeBaseIndex` storage.

```swift
public func ingestDocument(
    fileURL: URL,
    loader: (any DocumentLoader)? = nil,
    tags: [String] = [],
    userId: String? = nil,
    metadata: [String: String] = [:]
) async throws -> [DocumentChunk]
```

- **Parameters**:
  - `fileURL`: Local file URL. Supports `.pdf`, `.md`, `.swift`, `.py`, `.js`, `.ts`, `.csv`, `.json`, `.txt`, and more.
  - `loader`: Optional explicit loader. If `nil`, `AutoDocumentLoader` selects one based on file extension.
  - `tags`: Tags attached to all chunks for later filtering with `DocumentFilter`.
  - `userId`: Optional user scope for multi-user knowledge bases.
  - `metadata`: Optional extra string metadata stored with each chunk.
- **Returns**: Array of `DocumentChunk` records indexed into the `KnowledgeBaseIndex`.

---

### `ingestDocumentData(data:filename:tags:userId:metadata:)` ⭐ New

Ingests raw `Data` (e.g., from a network download or in-memory buffer) as a document.

```swift
public func ingestDocumentData(
    data: Data,
    filename: String,
    tags: [String] = [],
    userId: String? = nil,
    metadata: [String: String] = [:]
) async throws -> [DocumentChunk]
```

- **Parameters**:
  - `data`: Raw file bytes.
  - `filename`: Used to infer file type (e.g. `"report.md"`, `"data.csv"`).
  - `tags`, `userId`, `metadata`: Same as `ingestDocument`.
- **Returns**: Array of `DocumentChunk` records.

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

### `searchKnowledgeBase(query:limit:filter:)` ⭐ New

Searches the `KnowledgeBaseIndex` (document RAG index) by semantic similarity.

```swift
public func searchKnowledgeBase(
    query: String,
    limit: Int = 10,
    filter: DocumentFilter? = nil
) async throws -> [RetrievalResult]
```

- **Parameters**:
  - `query`: Natural language search query.
  - `limit`: Maximum number of chunks to return.
  - `filter`: Optional `DocumentFilter` to scope by tags, userId, date range, or MIME type.
- **Returns**: Array of `RetrievalResult` — each contains a `DocumentChunk` and a `score` (0.0–1.0).

```swift
let results = try await synapse.searchKnowledgeBase(
    query: "Q3 revenue growth drivers",
    limit: 5,
    filter: DocumentFilter(tags: ["finance"])
)
for result in results {
    print("Score: \(result.score) | \(result.chunk.documentTitle)")
}
```

---

### `retrieveContext(query:limit:filter:)` ⭐ New

Retrieves semantically relevant document chunks and assembles them into an LLM-ready `RAGContext` with inline `[1][2]` citation markers and a bibliography.

```swift
public func retrieveContext(
    query: String,
    limit: Int = 5,
    filter: DocumentFilter? = nil
) async throws -> RAGContext
```

- **Parameters**: Same as `searchKnowledgeBase`.
- **Returns**: A `RAGContext` containing:
  - `contextPrompt`: Formatted text block with numbered source headers, ready to append to an LLM prompt.
  - `citations`: Array of `Citation` structs for UI display.
  - `totalChunks`: Number of chunks included.
  - `bibliography()`: Formatted source reference list.

```swift
let ragContext = try await synapse.retrieveContext(
    query: "What were the main revenue drivers?",
    limit: 4
)

let fullPrompt = """
Use only the provided sources to answer.
\(ragContext.contextPrompt)
Question: What were the main revenue drivers?
"""
let answer = try await provider.generate(prompt: fullPrompt)
print(ragContext.bibliography())
// [1] "Q3 Strategy Deck" - Revenue Highlights, Page 5 (file:///docs/q3.pdf)
```

---



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
