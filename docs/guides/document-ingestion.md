# Document & RAG Ingestion Guide

SynapseMemory provides two complementary ingestion paths:

1. **`ingest(content:title:userId:tags:)`** — Supermemory-style raw text and bookmark ingestion for conversational memory and quick notes.
2. **`ingestDocument(fileURL:)` / `ingestDocumentData(data:filename:)`** — Full RAG pipeline: multi-format loaders, intelligent chunking, Vision OCR, and citation-tracked retrieval.

---

## 📄 Path 1: Raw Text Ingestion (`ingest()`)

The classic path for quickly ingesting text content, web bookmarks, and long-form notes:

```swift
import SynapseMemory

let synapse = try await SynapseClient(config: SynapseConfig())

try await synapse.ingest(
    content: "Swift 6 introduces strict concurrency checking by default, transforming data races into compile-time errors.",
    title: "Swift 6 Concurrency Notes",
    userId: "dev_user_1",
    tags: ["swift", "concurrency", "apple"]
)

let results = try await synapse.searchDocuments(
    query: "How does Swift 6 prevent data races?",
    userId: "dev_user_1"
)
for result in results {
    print("Matched: \(result.title)")
}
```

---

## 📂 Path 2: RAG Document Pipeline

The full RAG pipeline supports structured file ingestion with loader detection, chunking, embedding, and citation tracking.

### 2.1 Document Loaders

`AutoDocumentLoader` automatically selects the right loader based on file extension. You can also use loaders directly.

| Loader | Extensions | Capability |
|:---|:---|:---|
| `PDFDocumentLoader` | `.pdf` | PDFKit page extraction, outline headings |
| `MarkdownDocumentLoader` | `.md`, `.markdown` | Header-aware section splitting (`#`, `##`, `###`) |
| `CodeDocumentLoader` | `.swift`, `.py`, `.js`, `.ts`, `.go`, `.rs`, `.java`, `.kt`, `.html`, `.css` | Syntax symbol extraction (funcs, structs, classes) |
| `StructuredDataDocumentLoader` | `.csv`, `.tsv`, `.json` | Row-by-row semantic conversion |
| `PlainTextDocumentLoader` | `.txt`, `.log`, `.rtf` | Raw text |
| `AppleNotesExportLoader` | `.html`, `.eml` | Apple Notes and Mail archives |
| `AutoDocumentLoader` | (any) | Delegates to the correct loader automatically |

#### Loading a PDF

```swift
let pdfURL = Bundle.main.url(forResource: "TechSpec", withExtension: "pdf")!
let loader = PDFDocumentLoader()
let documents = try await loader.load(from: pdfURL)

print(documents[0].title)          // "Technical Specification"
print(documents[0].pages.count)    // 24
print(documents[0].sectionHeadings) // ["Introduction", "Architecture", ...]
```

#### Loading a Markdown File

```swift
let mdLoader = MarkdownDocumentLoader()
let docs = try await mdLoader.load(
    data: Data(contentsOf: docsURL),
    filename: "architecture.md",
    metadata: ["sourceURL": docsURL.absoluteString]
)
```

#### Loading a Swift Source File

```swift
let codeLoader = CodeDocumentLoader()
let docs = try await codeLoader.load(from: swiftFileURL)
print(docs[0].sectionHeadings) // ["struct AgentGraph", "func invoke(", "func stream("]
```

#### Using AutoDocumentLoader

```swift
let auto = AutoDocumentLoader()
let docs = try await auto.load(from: anyFileURL)
// Automatically picks PDF/Markdown/Code/CSV/etc. based on extension
```

---

### 2.2 Chunking Strategies

After loading, documents are chunked before indexing. Choose the chunking strategy that matches your content type.

| Strategy | Best For |
|:---|:---|
| `RecursiveCharacterChunker` | General text — tries `\n\n`, `\n`, `. `, space, character |
| `LayoutAwarePDFChunker` | PDFs — preserves page and section boundaries |
| `CodeSyntaxChunker` | Source code — groups by function/type scope |

#### RecursiveCharacterChunker

```swift
let chunker = RecursiveCharacterChunker(chunkSize: 600, chunkOverlap: 80)
let chunks = chunker.chunk(document: loadedDocument)

for chunk in chunks {
    print("[\(chunk.chunkIndex)/\(chunk.totalChunks)] \(chunk.text.prefix(60))...")
}
```

#### CodeSyntaxChunker

```swift
let codeChunker = CodeSyntaxChunker(maxLinesPerChunk: 40)
let chunks = codeChunker.chunk(document: swiftDocument)
// Groups consecutive function and type declarations into semantic units
```

---

### 2.3 Vision OCR — Ingest Images and Scanned PDFs

`OCRDocumentProcessor` uses Apple's Vision framework (`VNRecognizeTextRequest`) to extract text from images, diagrams, and scanned documents — fully on-device, at zero cost:

```swift
let ocrProcessor = OCRDocumentProcessor()
let imageURL = URL(fileURLWithPath: "/path/to/scanned-invoice.png")
let imageData = try Data(contentsOf: imageURL)

let extractedText = try await ocrProcessor.extractText(from: imageData)
print(extractedText) // "Invoice #1042 — Total: $4,800.00 — Due: 2026-09-01"

// Then ingest the extracted text
try await synapse.ingest(content: extractedText, title: "Invoice 1042", tags: ["finance"])
```

---

### 2.4 Citation Tracking & RAG Context

After ingestion, `RAGContextBuilder` assembles a ready-to-use LLM prompt with inline `[1]`, `[2]` citation markers and a formatted bibliography.

```swift
let chunk1 = DocumentChunk(
    documentTitle: "Q3 Strategy Deck",
    sourceURL: "file:///docs/q3.pdf",
    text: "Revenue grew 24% YoY, driven by cloud subscriptions.",
    chunkIndex: 0, totalChunks: 3, pageNumber: 5,
    sectionHeading: "Revenue Highlights"
)
let chunk2 = DocumentChunk(
    documentTitle: "CFO Report",
    sourceURL: "file:///docs/cfo-report.pdf",
    text: "Free cash flow reached $1.2B, above guidance of $950M.",
    chunkIndex: 0, totalChunks: 2, pageNumber: 2,
    sectionHeading: "Cash Flow Analysis"
)

let ragContext = RAGContextBuilder.build(chunks: [chunk1, chunk2], scores: [0.96, 0.91])

print(ragContext.contextPrompt)
// Source [1]: Q3 Strategy Deck - Revenue Highlights (Page 5)
// Revenue grew 24% YoY, driven by cloud subscriptions.
//
// Source [2]: CFO Report - Cash Flow Analysis (Page 2)
// Free cash flow reached $1.2B, above guidance of $950M.

print(ragContext.bibliography())
// [1] "Q3 Strategy Deck" - Revenue Highlights, Page 5 (file:///docs/q3.pdf)
// [2] "CFO Report" - Cash Flow Analysis, Page 2 (file:///docs/cfo-report.pdf)
```

---

### 2.5 SynapseClient RAG APIs

Use the high-level `SynapseClient` methods to ingest and retrieve in one call:

#### Ingest from a File URL

```swift
let chunks = try await synapse.ingestDocument(
    fileURL: URL(fileURLWithPath: "/reports/Q3.pdf"),
    tags: ["finance", "quarterly"],
    userId: "analyst_1"
)
print("Ingested \(chunks.count) chunks")
```

#### Ingest Raw Data

```swift
let mdText = "# Product Roadmap\nQ4: Launch v2.0 with multi-agent support..."
let chunks = try await synapse.ingestDocumentData(
    data: Data(mdText.utf8),
    filename: "roadmap.md",
    tags: ["product", "roadmap"]
)
```

#### Retrieve LLM-Ready RAG Context

```swift
let ragContext = try await synapse.retrieveContext(
    query: "What are the Q3 revenue highlights?",
    limit: 4,
    filter: DocumentFilter(tags: ["finance"])
)

// Pass directly to LLM
let prompt = """
Use only the following sources to answer the question.
\(ragContext.contextPrompt)

Question: What are the Q3 revenue highlights?
"""
let answer = try await provider.generate(prompt: prompt)
```

#### Search the Knowledge Base

```swift
let results = try await synapse.searchKnowledgeBase(
    query: "free cash flow guidance",
    limit: 5,
    filter: DocumentFilter(tags: ["finance"], userId: "analyst_1")
)

for result in results {
    print("Score: \(result.score) | \(result.chunk.documentTitle) p.\(result.chunk.pageNumber ?? 0)")
    print(result.chunk.text.prefix(120))
}
```

---

## 🔗 End-to-End Example

```swift
import SynapseMemory

// 1. Initialize with in-memory stores (or full CloudKit config for production)
let synapse = try await SynapseClient()

// 2. Ingest a PDF document
let pdfURL = Bundle.main.url(forResource: "Q3Report", withExtension: "pdf")!
let chunks = try await synapse.ingestDocument(
    fileURL: pdfURL,
    tags: ["finance", "Q3", "2026"]
)
print("✅ Ingested \(chunks.count) chunks from Q3 Report")

// 3. Retrieve context for a question
let ragContext = try await synapse.retrieveContext(
    query: "What was the operating revenue growth?",
    limit: 4
)

// 4. Build an LLM prompt with citations
let systemPrompt = "You are a financial analyst. Answer based only on the provided sources."
let userPrompt = """
\(ragContext.contextPrompt)

Question: What was the operating revenue growth in Q3?
"""

// 5. Generate the answer
let provider = AppleFoundationModelProvider.default
let answer = try await provider.generate(prompt: [.system(systemPrompt), .user(userPrompt)])
print(answer.text)

// 6. Show citations
print("\n\(ragContext.bibliography())")
// [1] "Q3 Financial Report" - Revenue Section, Page 4 (file:///Q3Report.pdf)
```
