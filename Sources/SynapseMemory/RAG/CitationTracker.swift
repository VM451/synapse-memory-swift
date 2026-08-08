import Foundation

/// Represents a source attribution citation for a retrieved document chunk.
public struct Citation: Sendable, Codable, Equatable, Identifiable {
    public var id: String { "\(chunkId)-\(citationIndex)" }
    public let citationIndex: Int
    public let chunkId: String
    public let documentTitle: String
    public let sourceURL: String?
    public let pageNumber: Int?
    public let sectionHeading: String?
    public let confidenceScore: Double
    public let snippet: String

    public init(
        citationIndex: Int,
        chunkId: String,
        documentTitle: String,
        sourceURL: String? = nil,
        pageNumber: Int? = nil,
        sectionHeading: String? = nil,
        confidenceScore: Double = 1.0,
        snippet: String
    ) {
        self.citationIndex = citationIndex
        self.chunkId = chunkId
        self.documentTitle = documentTitle
        self.sourceURL = sourceURL
        self.pageNumber = pageNumber
        self.sectionHeading = sectionHeading
        self.confidenceScore = confidenceScore
        self.snippet = snippet
    }

    /// Formats the citation as an inline markdown source reference line.
    public func formattedReference() -> String {
        let pageStr = pageNumber.map { ", Page \($0)" } ?? ""
        let secStr = sectionHeading.map { " - \($0)" } ?? ""
        let urlStr = sourceURL.map { " (\($0))" } ?? ""
        return "[\(citationIndex)] \"\(documentTitle)\"\(secStr)\(pageStr)\(urlStr)"
    }
}

/// Provenance audit record tracking which documents and chunks produced an agent answer.
public struct ProvenanceRecord: Sendable, Codable, Equatable, Identifiable {
    public let id: String
    public let query: String
    public let generatedAnswer: String?
    public let citations: [Citation]
    public let timestamp: Date
    public let userId: String?

    public init(
        id: String = UUID().uuidString,
        query: String,
        generatedAnswer: String? = nil,
        citations: [Citation],
        timestamp: Date = Date(),
        userId: String? = nil
    ) {
        self.id = id
        self.query = query
        self.generatedAnswer = generatedAnswer
        self.citations = citations
        self.timestamp = timestamp
        self.userId = userId
    }
}

/// Assembled RAG context prepared for injection into LLM prompts with inline citations.
public struct RAGContext: Sendable, Codable, Equatable {
    public let contextPrompt: String
    public let citations: [Citation]
    public let totalChunks: Int

    public init(contextPrompt: String, citations: [Citation], totalChunks: Int) {
        self.contextPrompt = contextPrompt
        self.citations = citations
        self.totalChunks = totalChunks
    }

    /// Renders a formatted bibliography of all cited sources.
    public func bibliography() -> String {
        guard !citations.isEmpty else { return "No citations." }
        return citations.map { $0.formattedReference() }.joined(separator: "\n")
    }
}

/// Builder that formats retrieved chunks into an LLM-ready context block with numbered `[1]`, `[2]` markers.
public struct RAGContextBuilder: Sendable {
    public init() {}

    public static func build(chunks: [DocumentChunk], scores: [Double] = []) -> RAGContext {
        guard !chunks.isEmpty else {
            return RAGContext(contextPrompt: "No relevant documents found.", citations: [], totalChunks: 0)
        }

        var citations: [Citation] = []
        var segments: [String] = []

        for (index, chunk) in chunks.enumerated() {
            let citationNumber = index + 1
            let score = index < scores.count ? scores[index] : 1.0

            let citation = Citation(
                citationIndex: citationNumber,
                chunkId: chunk.id,
                documentTitle: chunk.documentTitle,
                sourceURL: chunk.sourceURL,
                pageNumber: chunk.pageNumber,
                sectionHeading: chunk.sectionHeading,
                confidenceScore: score,
                snippet: String(chunk.text.prefix(200))
            )
            citations.append(citation)

            let header = "Source [\(citationNumber)]: \(chunk.documentTitle)\(chunk.sectionHeading.map { " - \($0)" } ?? "")\(chunk.pageNumber.map { " (Page \($0))" } ?? "")"
            segments.append("\(header)\n\(chunk.text)")
        }

        let fullPrompt = """
        === RELEVANT PERSONAL DOCUMENTS & KNOWLEDGE BASE ===
        \(segments.joined(separator: "\n\n---\n\n"))
        === END OF DOCUMENTS ===
        When answering, attribute your facts using citation numbers like [1], [2].
        """

        return RAGContext(contextPrompt: fullPrompt, citations: citations, totalChunks: chunks.count)
    }
}
