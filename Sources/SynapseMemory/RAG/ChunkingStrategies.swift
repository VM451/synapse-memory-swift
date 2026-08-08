import Foundation

/// Represents a single chunk of a loaded document with layout and provenance metadata.
public struct DocumentChunk: Sendable, Codable, Equatable, Identifiable {
    public let id: String
    public let documentTitle: String
    public let sourceURL: String?
    public let text: String
    public let chunkIndex: Int
    public let totalChunks: Int
    public let pageNumber: Int?
    public let sectionHeading: String?
    public let characterOffsetStart: Int
    public let characterOffsetEnd: Int

    public init(
        id: String = UUID().uuidString,
        documentTitle: String,
        sourceURL: String? = nil,
        text: String,
        chunkIndex: Int,
        totalChunks: Int,
        pageNumber: Int? = nil,
        sectionHeading: String? = nil,
        characterOffsetStart: Int = 0,
        characterOffsetEnd: Int = 0
    ) {
        self.id = id
        self.documentTitle = documentTitle
        self.sourceURL = sourceURL
        self.text = text
        self.chunkIndex = chunkIndex
        self.totalChunks = totalChunks
        self.pageNumber = pageNumber
        self.sectionHeading = sectionHeading
        self.characterOffsetStart = characterOffsetStart
        self.characterOffsetEnd = characterOffsetEnd
    }
}

/// Protocol defining document chunking strategies.
public protocol DocumentChunker: Sendable {
    func chunk(document: LoadedDocument) -> [DocumentChunk]
}

// MARK: - Recursive Character Chunker

public struct RecursiveCharacterChunker: DocumentChunker {
    public let chunkSize: Int
    public let chunkOverlap: Int
    public let separators: [String]

    public init(
        chunkSize: Int = 800,
        chunkOverlap: Int = 150,
        separators: [String] = ["\n\n", "\n", ". ", " ", ""]
    ) {
        self.chunkSize = chunkSize
        self.chunkOverlap = chunkOverlap
        self.separators = separators
    }

    public func chunk(document: LoadedDocument) -> [DocumentChunk] {
        let raw = document.content
        guard raw.count > chunkSize else {
            return [
                DocumentChunk(
                    documentTitle: document.title,
                    sourceURL: document.sourceURL,
                    text: raw,
                    chunkIndex: 0,
                    totalChunks: 1,
                    pageNumber: document.pages.first?.pageNumber,
                    sectionHeading: document.sectionHeadings.first,
                    characterOffsetStart: 0,
                    characterOffsetEnd: raw.count
                )
            ]
        }

        let pieces = splitText(text: raw, separators: separators)
        var chunks: [DocumentChunk] = []
        var offset = 0

        for (index, piece) in pieces.enumerated() {
            let pieceLen = piece.count
            chunks.append(
                DocumentChunk(
                    documentTitle: document.title,
                    sourceURL: document.sourceURL,
                    text: piece,
                    chunkIndex: index,
                    totalChunks: pieces.count,
                    pageNumber: document.pages.first?.pageNumber,
                    sectionHeading: document.sectionHeadings.first,
                    characterOffsetStart: offset,
                    characterOffsetEnd: offset + pieceLen
                )
            )
            offset += pieceLen
        }

        return chunks
    }

    private func splitText(text: String, separators: [String]) -> [String] {
        guard !separators.isEmpty else {
            var results: [String] = []
            var start = text.startIndex
            while start < text.endIndex {
                let end = text.index(start, offsetBy: chunkSize, limitedBy: text.endIndex) ?? text.endIndex
                let sub = String(text[start..<end])
                results.append(sub)
                if end == text.endIndex { break }
                start = text.index(start, offsetBy: max(1, chunkSize - chunkOverlap), limitedBy: text.endIndex) ?? text.endIndex
            }
            return results
        }

        let separator = separators[0]
        let remainingSeparators = Array(separators.dropFirst())

        if !separator.isEmpty && !text.contains(separator) {
            return splitText(text: text, separators: remainingSeparators)
        }

        let splits = separator.isEmpty ? [text] : text.components(separatedBy: separator)
        var result: [String] = []
        var current = ""

        for part in splits {
            let nextPart = current.isEmpty ? part : "\(current)\(separator)\(part)"
            if nextPart.count > chunkSize && !current.isEmpty {
                result.append(current.trimmingCharacters(in: .whitespacesAndNewlines))
                let tail = String(current.suffix(chunkOverlap))
                current = "\(tail)\(separator)\(part)"
            } else if part.count > chunkSize && !remainingSeparators.isEmpty {
                if !current.isEmpty {
                    result.append(current.trimmingCharacters(in: .whitespacesAndNewlines))
                    current = ""
                }
                let subPieces = splitText(text: part, separators: remainingSeparators)
                result.append(contentsOf: subPieces)
            } else {
                current = nextPart
            }
        }

        if !current.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            result.append(current.trimmingCharacters(in: .whitespacesAndNewlines))
        }

        return result
    }
}

// MARK: - Layout Aware PDF Chunker

public struct LayoutAwarePDFChunker: DocumentChunker {
    public let maxChunkSize: Int

    public init(maxChunkSize: Int = 1000) {
        self.maxChunkSize = maxChunkSize
    }

    public func chunk(document: LoadedDocument) -> [DocumentChunk] {
        var chunks: [DocumentChunk] = []
        var chunkIndex = 0

        for page in document.pages {
            let pageText = page.content
            if pageText.count <= maxChunkSize {
                chunks.append(
                    DocumentChunk(
                        documentTitle: document.title,
                        sourceURL: document.sourceURL,
                        text: pageText,
                        chunkIndex: chunkIndex,
                        totalChunks: 0, // updated below
                        pageNumber: page.pageNumber,
                        sectionHeading: page.sectionHeading ?? "Page \(page.pageNumber)"
                    )
                )
                chunkIndex += 1
            } else {
                // Split multi-paragraph page
                let recursive = RecursiveCharacterChunker(chunkSize: maxChunkSize, chunkOverlap: 100)
                let subChunks = recursive.chunk(document: LoadedDocument(title: document.title, content: pageText))
                for sub in subChunks {
                    chunks.append(
                        DocumentChunk(
                            documentTitle: document.title,
                            sourceURL: document.sourceURL,
                            text: sub.text,
                            chunkIndex: chunkIndex,
                            totalChunks: 0,
                            pageNumber: page.pageNumber,
                            sectionHeading: page.sectionHeading ?? "Page \(page.pageNumber)"
                        )
                    )
                    chunkIndex += 1
                }
            }
        }

        let total = chunks.count
        return chunks.map {
            DocumentChunk(
                id: $0.id,
                documentTitle: $0.documentTitle,
                sourceURL: $0.sourceURL,
                text: $0.text,
                chunkIndex: $0.chunkIndex,
                totalChunks: total,
                pageNumber: $0.pageNumber,
                sectionHeading: $0.sectionHeading,
                characterOffsetStart: $0.characterOffsetStart,
                characterOffsetEnd: $0.characterOffsetEnd
            )
        }
    }
}

// MARK: - Code Syntax Chunker

public struct CodeSyntaxChunker: DocumentChunker {
    public let maxLinesPerChunk: Int

    public init(maxLinesPerChunk: Int = 60) {
        self.maxLinesPerChunk = maxLinesPerChunk
    }

    public func chunk(document: LoadedDocument) -> [DocumentChunk] {
        let lines = document.content.components(separatedBy: .newlines)
        guard lines.count > maxLinesPerChunk else {
            return [
                DocumentChunk(
                    documentTitle: document.title,
                    sourceURL: document.sourceURL,
                    text: document.content,
                    chunkIndex: 0,
                    totalChunks: 1,
                    sectionHeading: document.sectionHeadings.first
                )
            ]
        }

        var chunks: [DocumentChunk] = []
        var currentLines: [String] = []
        var currentHeading: String? = document.sectionHeadings.first
        var index = 0

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("func ") || trimmed.hasPrefix("struct ") || trimmed.hasPrefix("class ") || trimmed.hasPrefix("actor ") || trimmed.hasPrefix("def ") {
                if currentLines.count >= maxLinesPerChunk {
                    let block = currentLines.joined(separator: "\n")
                    chunks.append(DocumentChunk(
                        documentTitle: document.title,
                        sourceURL: document.sourceURL,
                        text: block,
                        chunkIndex: index,
                        totalChunks: 0,
                        sectionHeading: currentHeading
                    ))
                    index += 1
                    currentLines.removeAll()
                }
                currentHeading = trimmed
            }
            currentLines.append(line)
        }

        if !currentLines.isEmpty {
            let block = currentLines.joined(separator: "\n")
            chunks.append(DocumentChunk(
                documentTitle: document.title,
                sourceURL: document.sourceURL,
                text: block,
                chunkIndex: index,
                totalChunks: 0,
                sectionHeading: currentHeading
            ))
        }

        let total = chunks.count
        return chunks.map {
            DocumentChunk(
                id: $0.id,
                documentTitle: $0.documentTitle,
                sourceURL: $0.sourceURL,
                text: $0.text,
                chunkIndex: $0.chunkIndex,
                totalChunks: total,
                pageNumber: $0.pageNumber,
                sectionHeading: $0.sectionHeading
            )
        }
    }
}
