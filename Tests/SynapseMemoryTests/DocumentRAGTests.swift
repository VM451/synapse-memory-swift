import Testing
import Foundation
@testable import SynapseMemory

@Suite("Document RAG & Multi-Format Loaders Tests")
struct DocumentRAGTests {

    @Test("MarkdownDocumentLoader parses headings and breaks into sections")
    func markdownLoaderParsing() async throws {
        let mdText = """
        # Architecture Overview
        SynapseMemory is a bi-temporal knowledge graph and local vector store.

        ## RAG Ingestion Pipeline
        Documents are loaded, chunked, and embedded into a dedicated knowledge base index.

        ### PDF and Code Support
        Supports PDFKit and syntax-aware source file chunking.
        """

        let loader = MarkdownDocumentLoader()
        let docs = try await loader.load(data: Data(mdText.utf8), filename: "overview.md", metadata: [:])

        #expect(docs.count == 1)
        let doc = docs[0]
        #expect(doc.title == "Architecture Overview")
        #expect(doc.sectionHeadings.contains("RAG Ingestion Pipeline"))
        #expect(doc.sectionHeadings.contains("PDF and Code Support"))
        #expect(doc.pages.count >= 2)
    }

    @Test("CodeDocumentLoader extracts language declarations and functions")
    func codeDocumentLoader() async throws {
        let swiftCode = """
        import Foundation

        public struct AgentMemory: Sendable {
            public let id: String
        }

        public func recall(query: String) async -> [String] {
            return ["Result"]
        }
        """

        let loader = CodeDocumentLoader()
        let docs = try await loader.load(data: Data(swiftCode.utf8), filename: "AgentMemory.swift", metadata: [:])

        #expect(docs.count == 1)
        let doc = docs[0]
        #expect(doc.title == "AgentMemory.swift")
        #expect(doc.fileExtension == "swift")
        #expect(doc.sectionHeadings.contains { $0.contains("struct AgentMemory") })
        #expect(doc.sectionHeadings.contains { $0.contains("func recall") })
    }

    @Test("StructuredDataDocumentLoader transforms CSV rows into semantic key-value strings")
    func csvLoaderParsing() async throws {
        let csv = """
        "Product","Category","Price","Units"
        "MacBook Pro","Hardware","2499","150"
        "iPad Pro","Hardware","1099","300"
        """

        let loader = StructuredDataDocumentLoader()
        let docs = try await loader.load(data: Data(csv.utf8), filename: "inventory.csv", metadata: [:])

        #expect(docs.count == 1)
        let doc = docs[0]
        #expect(doc.content.contains("Product: MacBook Pro | Category: Hardware | Price: 2499 | Units: 150"))
        #expect(doc.sectionHeadings.contains("Product"))
    }

    @Test("KnowledgeBaseIndex and SynapseClient ingest local documents and query with hybrid search")
    func knowledgeBaseIndexAndClientIngest() async throws {
        let vectorStore = try LocalVectorStore(inMemory: true)
        let graphStore = try LocalGraphStore(inMemory: true)
        let config = SynapseConfig(
            llmProvider: MockLLMProvider(),
            embeddingProvider: MockEmbeddingProvider(vectorDimension: 64),
            customVectorStore: vectorStore,
            customGraphStore: graphStore,
            enableAutoSync: false,
            enableSpotlightIndexing: false
        )
        let client = try await SynapseClient(config: config)

        let mdData = """
        # Q3 Financial Report
        Operating revenue grew by 24% year-over-year.
        Free cash flow reached 1.2 billion USD.
        Key drivers included cloud infrastructure and developer subscriptions.
        """

        let chunks = try await client.ingestDocumentData(
            data: Data(mdData.utf8),
            filename: "Q3_Report.md",
            tags: ["finance", "quarterly", "report"]
        )

        #expect(chunks.count >= 1)

        let filter = DocumentFilter(tags: ["finance"])
        let results = try await client.searchKnowledgeBase(query: "operating revenue growth", limit: 3, filter: filter)

        #expect(!results.isEmpty)
        let first = results[0]
        #expect(first.chunk.documentTitle == "Q3 Financial Report" || first.chunk.documentTitle == "Q3_Report.md")
        #expect(first.score > 0.0)
    }
}
