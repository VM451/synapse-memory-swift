# RAG Pipeline Architecture

SynapseMemory's RAG (Retrieval-Augmented Generation) pipeline is a fully on-device, zero-cloud document intelligence stack. It transforms raw files into LLM-ready context blocks with numbered citations and structured bibliographies.

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                        Source Documents                         │
│  PDF, Markdown, Swift/Python/JS, CSV/JSON, Notes, Images, Text  │
└──────────────────────────────┬──────────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────────┐
│                       Document Loaders                          │
│  AutoDocumentLoader → PDFDocumentLoader / MarkdownDocumentLoader│
│                     / CodeDocumentLoader / StructuredDataLoader  │
│                     / AppleNotesExportLoader / PlainTextLoader   │
│                     / OCRDocumentProcessor (Apple Vision OCR)    │
└──────────────────────────────┬──────────────────────────────────┘
                               │ LoadedDocument
                               ▼
┌─────────────────────────────────────────────────────────────────┐
│                      Chunking Strategies                        │
│  RecursiveCharacterChunker / LayoutAwarePDFChunker              │
│  CodeSyntaxChunker                                              │
└──────────────────────────────┬──────────────────────────────────┘
                               │ [DocumentChunk]
                               ▼
┌─────────────────────────────────────────────────────────────────┐
│                    KnowledgeBaseIndex (actor)                   │
│  • Generates dense vector embeddings (Accelerate SIMD)          │
│  • Stores chunks + vectors + tags + userId                      │
│  • Supports DocumentFilter (tags, userId, dateRange, mimeType)  │
└──────────────────────────────┬──────────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────────┐
│                       RAGRetriever                              │
│  • Cosine similarity ranking of query vs stored chunks          │
│  • Applies DocumentFilter constraints                           │
│  • Returns [RetrievalResult] (chunk + score)                    │
└──────────────────────────────┬──────────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────────┐
│                      RAGContextBuilder                          │
│  • Assembles LLM prompt with "Source [1]: Title - Section"      │
│  • Adds inline [1][2] citation markers                          │
│  • Generates formatted bibliography                             │
└──────────────────────────────┬──────────────────────────────────┘
                               │ RAGContext
                               ▼
┌─────────────────────────────────────────────────────────────────┐
│                    LLM Prompt + Generation                      │
│  Apple Foundation Models / Gemini / Claude / GPT-4o / Ollama    │
└─────────────────────────────────────────────────────────────────┘
```

---

## 1. Loader Selection Guide

| File Type | Recommended Loader | Why |
|:---|:---|:---|
| PDF reports, books, papers | `PDFDocumentLoader` | Preserves page numbers and outline headings |
| Markdown docs, READMEs | `MarkdownDocumentLoader` | Splits at `#`, `##`, `###` boundaries |
| Swift, Python, JS source files | `CodeDocumentLoader` | Extracts function, class, and struct symbols |
| CSV, TSV, JSON tables | `StructuredDataDocumentLoader` | Converts rows to semantic key-value strings |
| Apple Notes exports, `.eml` | `AppleNotesExportLoader` | Parses HTML notes and email archives |
| Plain text, logs | `PlainTextDocumentLoader` | No-op loader — directly returns content |
| Unknown / mixed | `AutoDocumentLoader` | Inspects extension and delegates |
| Scanned docs, screenshots | `OCRDocumentProcessor` | Apple Vision OCR — fully on-device |

---

## 2. Chunking Strategy Selection Guide

| Content Type | Recommended Strategy | Key Parameters |
|:---|:---|:---|
| General prose, articles, reports | `RecursiveCharacterChunker` | `chunkSize: 600`, `chunkOverlap: 80` |
| PDFs with clear layout sections | `LayoutAwarePDFChunker` | `maxChunkSize: 1000` |
| Source code files | `CodeSyntaxChunker` | `maxLinesPerChunk: 40` |

### Tuning RecursiveCharacterChunker

The `RecursiveCharacterChunker` tries each separator in order (`"\n\n"`, `"\n"`, `". "`, `" "`, `""`) until it can split the text without exceeding `chunkSize`. Set `chunkOverlap` to retain context continuity across chunk boundaries:

```swift
// Fine-grained for dense financial documents
let chunker = RecursiveCharacterChunker(chunkSize: 400, chunkOverlap: 60)

// Broader for narrative text where context spans paragraphs
let chunker = RecursiveCharacterChunker(chunkSize: 900, chunkOverlap: 150)
```

---

## 3. Filtering Retrieval Results

Use `DocumentFilter` to scope retrievals to a subset of the knowledge base:

```swift
// Only return chunks tagged "finance" added by "analyst_1"
let filter = DocumentFilter(
    tags: ["finance"],
    userId: "analyst_1"
)

// Only PDFs added in the last 7 days
let recentFilter = DocumentFilter(
    mimeTypes: ["application/pdf"],
    dateRange: DateInterval(start: Date().addingTimeInterval(-7 * 86400), end: Date())
)

let results = try await synapse.searchKnowledgeBase(
    query: "operating cash flow",
    limit: 5,
    filter: filter
)
```

---

## 4. Citation Tracking

Every `DocumentChunk` carries full provenance metadata:

| Field | Description |
|:---|:---|
| `documentTitle` | Title of the source document |
| `sourceURL` | File URL or remote URL of the original |
| `pageNumber` | Page number within the document (if applicable) |
| `sectionHeading` | Nearest heading in the document |
| `chunkIndex` / `totalChunks` | Position within the source document |
| `characterOffsetStart` / `End` | Byte-level position within the original text |

`RAGContextBuilder` assembles these into a numbered prompt and bibliography:

```swift
let ragContext = RAGContextBuilder.build(chunks: retrievedChunks, scores: retrievalScores)

// Use in LLM prompt
let fullPrompt = """
Answer the following question using only the provided sources.
\(ragContext.contextPrompt)

Question: \(userQuery)
"""

// Show sources to user
print(ragContext.bibliography())
// [1] "Q3 Strategy Deck" - Revenue Highlights, Page 5 (file:///docs/q3.pdf)
// [2] "CFO Report" - Cash Flow Analysis, Page 2 (file:///docs/cfo.pdf)
```

---

## 5. Full End-to-End Pipeline

```swift
import SynapseMemory

let synapse = try await SynapseClient()

// Step 1: Ingest multiple document types
let pdfChunks = try await synapse.ingestDocument(
    fileURL: URL(fileURLWithPath: "/docs/strategy.pdf"),
    tags: ["strategy", "2026"]
)
let mdChunks = try await synapse.ingestDocumentData(
    data: try Data(contentsOf: roadmapURL),
    filename: "roadmap.md",
    tags: ["product", "roadmap"]
)
print("Indexed \(pdfChunks.count + mdChunks.count) total chunks")

// Step 2: Retrieve with filter
let ragContext = try await synapse.retrieveContext(
    query: "What are the key product initiatives for Q4?",
    limit: 6,
    filter: DocumentFilter(tags: ["product"])
)

// Step 3: Pass to LLM
let answer = try await AppleFoundationModelProvider.default.generate(prompt: [
    .system("Answer only from the provided sources."),
    .user(ragContext.contextPrompt + "\n\nQuestion: What are the key Q4 product initiatives?")
])

print(answer.text)
print("\nSources:\n\(ragContext.bibliography())")
```

---

## 6. Architecture Principles

- **100% On-Device**: All embedding, chunking, OCR, and indexing runs locally via Accelerate SIMD, Apple Vision, and SQLite — zero cloud.
- **Zero Mandatory LLM**: The RAG pipeline works with any `EmbeddingProvider` (including the mock). Only the final answer generation requires an LLM.
- **`KnowledgeBaseIndex` is separate from `LocalVectorStore`**: The RAG index is purpose-built for document chunks with rich provenance metadata; the vector store handles conversational memory items.
- **All actors are Swift 6 strict concurrency safe**: `KnowledgeBaseIndex` is an `actor` — all writes and reads are data-race free.
