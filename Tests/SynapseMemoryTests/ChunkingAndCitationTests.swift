import Testing
import Foundation
@testable import SynapseMemory

@Suite("Chunking Strategies & Citation Tracker Tests")
struct ChunkingAndCitationTests {

    @Test("RecursiveCharacterChunker splits long text while respecting chunk overlap")
    func recursiveCharacterChunkerSplits() {
        let chunker = RecursiveCharacterChunker(chunkSize: 100, chunkOverlap: 20)
        let paragraph = """
        Apple Silicon features unified memory architecture. This allows high-throughput neural engine execution directly on device without sending private data to cloud data centers.
        Agents require efficient state management, working memory blocks, and vector indexes.
        """

        let doc = LoadedDocument(title: "Architecture", content: paragraph)
        let chunks = chunker.chunk(document: doc)

        #expect(chunks.count >= 2)
        #expect(chunks[0].documentTitle == "Architecture")
        #expect(chunks[0].chunkIndex == 0)
    }

    @Test("CodeSyntaxChunker groups by functions and types")
    func codeSyntaxChunkerGroups() {
        let chunker = CodeSyntaxChunker(maxLinesPerChunk: 5)
        let code = """
        struct Config {
            var id: String
        }

        func processA() {
            print("A")
        }

        func processB() {
            print("B")
        }

        func processC() {
            print("C")
        }
        """

        let doc = LoadedDocument(title: "Pipeline.swift", content: code)
        let chunks = chunker.chunk(document: doc)

        #expect(chunks.count >= 2)
        #expect(chunks[0].documentTitle == "Pipeline.swift")
    }

    @Test("RAGContextBuilder creates prompt with inline citations and formatted bibliography")
    func ragContextBuilderCitations() {
        let chunk1 = DocumentChunk(
            documentTitle: "Q3 Strategy",
            sourceURL: "file:///docs/q3.pdf",
            text: "Targeting 30% ARR growth in enterprise developer tier.",
            chunkIndex: 0,
            totalChunks: 2,
            pageNumber: 4,
            sectionHeading: "Growth Targets"
        )
        let chunk2 = DocumentChunk(
            documentTitle: "Privacy Manifesto",
            sourceURL: "file:///docs/privacy.md",
            text: "All embeddings are computed on-device using Accelerate SIMD.",
            chunkIndex: 1,
            totalChunks: 2,
            pageNumber: 1,
            sectionHeading: "Zero Cloud"
        )

        let ragContext = RAGContextBuilder.build(chunks: [chunk1, chunk2], scores: [0.95, 0.88])

        #expect(ragContext.totalChunks == 2)
        #expect(ragContext.citations.count == 2)

        let prompt = ragContext.contextPrompt
        #expect(prompt.contains("Source [1]: Q3 Strategy - Growth Targets (Page 4)"))
        #expect(prompt.contains("Source [2]: Privacy Manifesto - Zero Cloud (Page 1)"))

        let bib = ragContext.bibliography()
        #expect(bib.contains("[1] \"Q3 Strategy\" - Growth Targets, Page 4 (file:///docs/q3.pdf)"))
        #expect(bib.contains("[2] \"Privacy Manifesto\" - Zero Cloud, Page 1 (file:///docs/privacy.md)"))
    }

    @Test("SynapseClient.retrieveContext generates LLM-ready prompt with citations")
    func synapseClientRetrieveContext() async throws {
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

        let article = """
        # Apple Neural Engine
        The 16-core Neural Engine delivers up to 38 trillion operations per second.
        It accelerates vector embeddings and local on-device LLM inference.
        """

        try await client.ingestDocumentData(
            data: Data(article.utf8),
            filename: "NeuralEngine.md",
            tags: ["hardware", "apple"]
        )

        let ragContext = try await client.retrieveContext(query: "operations per second neural engine", limit: 2)

        #expect(!ragContext.citations.isEmpty)
        #expect(ragContext.contextPrompt.contains("NeuralEngine.md") || ragContext.contextPrompt.contains("Apple Neural Engine"))
        #expect(ragContext.bibliography().contains("[1]"))
    }
}
