import Foundation

/// Filter criteria for querying the personal document knowledge base.
public struct DocumentFilter: Sendable, Codable, Equatable {
    public let userId: String?
    public let tags: [String]
    public let mimeType: String?
    public let sourceURLPrefix: String?

    public init(
        userId: String? = nil,
        tags: [String] = [],
        mimeType: String? = nil,
        sourceURLPrefix: String? = nil
    ) {
        self.userId = userId
        self.tags = tags
        self.mimeType = mimeType
        self.sourceURLPrefix = sourceURLPrefix
    }
}

/// A structured retrieval match result from the knowledge base.
public struct RetrievalResult: Sendable, Identifiable, Equatable {
    public var id: String { chunk.id }
    public let chunk: DocumentChunk
    public let score: Double
    public let citation: Citation

    public init(chunk: DocumentChunk, score: Double, citationIndex: Int = 1) {
        self.chunk = chunk
        self.score = score
        self.citation = Citation(
            citationIndex: citationIndex,
            chunkId: chunk.id,
            documentTitle: chunk.documentTitle,
            sourceURL: chunk.sourceURL,
            pageNumber: chunk.pageNumber,
            sectionHeading: chunk.sectionHeading,
            confidenceScore: score,
            snippet: String(chunk.text.prefix(200))
        )
    }
}

/// Dedicated retrieval-optimized Knowledge Base Index for personal and enterprise documents.
public actor KnowledgeBaseIndex {
    private var storedChunks: [String: (chunk: DocumentChunk, vector: [Float], tags: [String], userId: String?)] = [:]
    private let chunker: any DocumentChunker
    private let embeddingProvider: any EmbeddingProvider

    public init(
        chunker: any DocumentChunker = RecursiveCharacterChunker(),
        embeddingProvider: any EmbeddingProvider = MockEmbeddingProvider()
    ) {
        self.chunker = chunker
        self.embeddingProvider = embeddingProvider
    }

    /// Indexes a loaded document by chunking, generating embeddings, and storing structured metadata.
    public func index(
        document: LoadedDocument,
        tags: [String] = [],
        userId: String? = nil
    ) async throws -> [DocumentChunk] {
        let chunks = chunker.chunk(document: document)
        for chunk in chunks {
            let vector = try await embeddingProvider.embed(text: "\(chunk.documentTitle)\n\(chunk.text)")
            storedChunks[chunk.id] = (chunk: chunk, vector: vector, tags: tags, userId: userId)
        }
        return chunks
    }

    /// Queries the knowledge base index with hybrid semantic similarity and keyword rank fusion.
    public func retrieve(
        query: String,
        limit: Int = 5,
        filter: DocumentFilter? = nil
    ) async throws -> [RetrievalResult] {
        guard !storedChunks.isEmpty else { return [] }

        let queryVector = try await embeddingProvider.embed(text: query)
        var scored: [(chunk: DocumentChunk, score: Double)] = []

        for (_, entry) in storedChunks {
            // Apply filtering
            if let filter = filter {
                if let u = filter.userId, entry.userId != nil, entry.userId != u {
                    continue
                }
                if !filter.tags.isEmpty {
                    let matchingTags = Set(filter.tags).intersection(Set(entry.tags))
                    if matchingTags.isEmpty { continue }
                }
            }

            // Semantic vector similarity
            let sim = VectorMath.cosineSimilarity(queryVector, entry.vector)

            // Keyword boost
            var keywordBonus = 0.0
            let queryTerms = query.lowercased().components(separatedBy: .whitespacesAndNewlines).filter { $0.count > 2 }
            let lowerText = entry.chunk.text.lowercased()
            for term in queryTerms {
                if lowerText.contains(term) {
                    keywordBonus += 0.1
                }
            }

            let finalScore = Double(sim) + keywordBonus
            scored.append((chunk: entry.chunk, score: finalScore))
        }

        let sorted = scored.sorted { $0.score > $1.score }.prefix(limit)
        return sorted.enumerated().map { index, match in
            RetrievalResult(chunk: match.chunk, score: match.score, citationIndex: index + 1)
        }
    }

    /// Clears all indexed documents from this knowledge base.
    public func reset() {
        storedChunks.removeAll()
    }

    /// Returns the total number of indexed document chunks.
    public func count() -> Int {
        storedChunks.count
    }
}

/// High-level retriever querying the KnowledgeBaseIndex and formatting LLM-ready RAG context.
public struct RAGRetriever: Sendable {
    public let index: KnowledgeBaseIndex

    public init(index: KnowledgeBaseIndex) {
        self.index = index
    }

    /// Retrieves relevant chunks and returns formatted RAGContext.
    public func retrieveContext(
        query: String,
        limit: Int = 5,
        filter: DocumentFilter? = nil
    ) async throws -> RAGContext {
        let results = try await index.retrieve(query: query, limit: limit, filter: filter)
        let chunks = results.map(\.chunk)
        let scores = results.map(\.score)
        return RAGContextBuilder.build(chunks: chunks, scores: scores)
    }
}
