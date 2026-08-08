# Document & Bookmark Ingestion Guide

Inspired by **Supermemory**, SynapseMemory provides a native document ingestion engine (`ingest()`) that transforms long-form text, web bookmarks, PDFs, and notes into semantically chunked memory items with automated tag generation.

---

## ⚙️ How Ingestion Works

When calling `synapse.ingest(content:title:userId:tags:)`:

1. **Content Chunking (`ContentChunker`)**: Splits raw document text using a configurable sliding-window algorithm (e.g. 500-token chunks with 50-token overlap) to preserve semantic context across chunk boundaries.
2. **Auto-Tag Extraction**: Automatically generates descriptive tags based on content topics if explicit tags are omitted.
3. **Vector & BM25 Indexing**: Generates dense vector embeddings for each chunk and writes full-text indexes to SQLite FTS5.
4. **Metadata Tracking**: Preserves document titles, source URLs, timestamps, and chunk indices.

---

## 💻 API Usage & Code Examples

### 1. Basic Ingestion

```swift
import SynapseMemory

let synapse = try await SynapseClient(config: SynapseConfig())

let documentText = """
Swift 6 introduces strict concurrency checking by default, transforming data races into compile-time errors.
Sendable protocols and isolated actors ensure thread safety across Apple Silicon performance cores.
"""

try await synapse.ingest(
    content: documentText,
    title: "Swift 6 Concurrency Notes",
    userId: "dev_user_1",
    tags: ["swift", "concurrency", "apple"]
)
```

### 2. Searching Ingested Documents

```swift
let searchResults = try await synapse.search(
    query: "How does Swift 6 prevent data races?",
    userId: "dev_user_1"
)

for result in searchResults {
    print("Matched Chunk: \(result.item.memory)")
    print("Score: \(result.score)")
}
```
