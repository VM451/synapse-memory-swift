import Foundation
#if canImport(PDFKit)
import PDFKit
#endif
#if canImport(UniformTypeIdentifiers)
import UniformTypeIdentifiers
#endif

/// Represents an extracted page from a document.
public struct DocumentPage: Sendable, Codable, Equatable {
    public let pageNumber: Int
    public let content: String
    public let sectionHeading: String?

    public init(pageNumber: Int, content: String, sectionHeading: String? = nil) {
        self.pageNumber = pageNumber
        self.content = content
        self.sectionHeading = sectionHeading
    }
}

/// Represents the extracted structured content and metadata of a loaded document.
public struct LoadedDocument: Sendable, Codable, Equatable, Identifiable {
    public let id: String
    public let title: String
    public let content: String
    public let sourceURL: String?
    public let mimeType: String
    public let fileExtension: String
    public let pages: [DocumentPage]
    public let sectionHeadings: [String]
    public let metadata: [String: String]

    public init(
        id: String = UUID().uuidString,
        title: String,
        content: String,
        sourceURL: String? = nil,
        mimeType: String = "text/plain",
        fileExtension: String = "txt",
        pages: [DocumentPage] = [],
        sectionHeadings: [String] = [],
        metadata: [String: String] = [:]
    ) {
        self.id = id
        self.title = title
        self.content = content
        self.sourceURL = sourceURL
        self.mimeType = mimeType
        self.fileExtension = fileExtension
        self.pages = pages
        self.sectionHeadings = sectionHeadings
        self.metadata = metadata
    }
}

/// Protocol defining document loaders that ingest raw data or files into structured LoadedDocuments.
public protocol DocumentLoader: Sendable {
    var supportedExtensions: [String] { get }
    func load(from url: URL) async throws -> [LoadedDocument]
    func load(data: Data, filename: String, metadata: [String: String]) async throws -> [LoadedDocument]
}

// MARK: - Plain Text & RTF Loader

public struct PlainTextDocumentLoader: DocumentLoader {
    public let supportedExtensions: [String] = ["txt", "text", "rtf", "log", "org"]

    public init() {}

    public func load(from url: URL) async throws -> [LoadedDocument] {
        let content = try String(contentsOf: url, encoding: .utf8)
        let filename = url.lastPathComponent
        return [
            LoadedDocument(
                title: url.deletingPathExtension().lastPathComponent,
                content: content,
                sourceURL: url.absoluteString,
                mimeType: "text/plain",
                fileExtension: url.pathExtension.lowercased(),
                pages: [DocumentPage(pageNumber: 1, content: content)],
                metadata: ["filename": filename]
            )
        ]
    }

    public func load(data: Data, filename: String, metadata: [String: String]) async throws -> [LoadedDocument] {
        let content = String(decoding: data, as: UTF8.self)
        let ext = (filename as NSString).pathExtension.lowercased()
        return [
            LoadedDocument(
                title: (filename as NSString).deletingPathExtension,
                content: content,
                sourceURL: nil,
                mimeType: "text/plain",
                fileExtension: ext.isEmpty ? "txt" : ext,
                pages: [DocumentPage(pageNumber: 1, content: content)],
                metadata: metadata
            )
        ]
    }
}

// MARK: - Markdown Loader (Heading & Section Aware)

public struct MarkdownDocumentLoader: DocumentLoader {
    public let supportedExtensions: [String] = ["md", "markdown", "mdown", "mkd"]

    public init() {}

    public func load(from url: URL) async throws -> [LoadedDocument] {
        let text = try String(contentsOf: url, encoding: .utf8)
        return try await load(data: Data(text.utf8), filename: url.lastPathComponent, metadata: ["sourceURL": url.absoluteString])
    }

    public func load(data: Data, filename: String, metadata: [String: String]) async throws -> [LoadedDocument] {
        let text = String(decoding: data, as: UTF8.self)
        let lines = text.components(separatedBy: .newlines)

        var headings: [String] = []
        var pages: [DocumentPage] = []
        var currentPageText = ""
        var currentHeading = "Introduction"
        var pageIndex = 1

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("#") {
                if !currentPageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    pages.append(DocumentPage(pageNumber: pageIndex, content: currentPageText.trimmingCharacters(in: .whitespacesAndNewlines), sectionHeading: currentHeading))
                    pageIndex += 1
                    currentPageText = ""
                }
                let headingTitle = trimmed.trimmingCharacters(in: CharacterSet(charactersIn: "# ")).trimmingCharacters(in: .whitespaces)
                currentHeading = headingTitle
                headings.append(headingTitle)
            }
            currentPageText += line + "\n"
        }

        if !currentPageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            pages.append(DocumentPage(pageNumber: pageIndex, content: currentPageText.trimmingCharacters(in: .whitespacesAndNewlines), sectionHeading: currentHeading))
        }

        let title = headings.first ?? (filename as NSString).deletingPathExtension

        return [
            LoadedDocument(
                title: title,
                content: text,
                sourceURL: metadata["sourceURL"],
                mimeType: "text/markdown",
                fileExtension: "md",
                pages: pages.isEmpty ? [DocumentPage(pageNumber: 1, content: text)] : pages,
                sectionHeadings: headings,
                metadata: metadata
            )
        ]
    }
}

// MARK: - Code Files Loader (Syntax and Symbol Aware)

public struct CodeDocumentLoader: DocumentLoader {
    public let supportedExtensions: [String] = [
        "swift", "py", "js", "ts", "tsx", "jsx", "go", "rs", "cpp", "c", "h", "m", "java", "kt", "html", "css", "yaml", "yml"
    ]

    public init() {}

    public func load(from url: URL) async throws -> [LoadedDocument] {
        let text = try String(contentsOf: url, encoding: .utf8)
        return try await load(data: Data(text.utf8), filename: url.lastPathComponent, metadata: ["sourceURL": url.absoluteString])
    }

    public func load(data: Data, filename: String, metadata: [String: String]) async throws -> [LoadedDocument] {
        let text = String(decoding: data, as: UTF8.self)
        let lines = text.components(separatedBy: .newlines)
        let ext = (filename as NSString).pathExtension.lowercased()

        var symbols: [String] = []
        let declKeywords = ["func ", "struct ", "class ", "enum ", "actor ", "protocol ", "def ", "function ", "typealias ", "interface "]
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if declKeywords.contains(where: { trimmed.contains($0) }) {
                symbols.append(trimmed)
            }
        }

        return [
            LoadedDocument(
                title: filename,
                content: text,
                sourceURL: metadata["sourceURL"],
                mimeType: "text/x-\(ext)",
                fileExtension: ext,
                pages: [DocumentPage(pageNumber: 1, content: text, sectionHeading: symbols.first)],
                sectionHeadings: symbols,
                metadata: metadata
            )
        ]
    }
}

// MARK: - Structured CSV & JSON Data Loader

public struct StructuredDataDocumentLoader: DocumentLoader {
    public let supportedExtensions: [String] = ["csv", "tsv", "json"]

    public init() {}

    public func load(from url: URL) async throws -> [LoadedDocument] {
        let data = try Data(contentsOf: url)
        return try await load(data: data, filename: url.lastPathComponent, metadata: ["sourceURL": url.absoluteString])
    }

    public func load(data: Data, filename: String, metadata: [String: String]) async throws -> [LoadedDocument] {
        let ext = (filename as NSString).pathExtension.lowercased()
        let rawText = String(decoding: data, as: UTF8.self)

        if ext == "json" {
            // Attempt to parse JSON into human-readable semantic key-value records
            if let obj = try? JSONSerialization.jsonObject(with: data) {
                let prettyData = (try? JSONSerialization.data(withJSONObject: obj, options: [.prettyPrinted, .sortedKeys])) ?? data
                let formatted = String(decoding: prettyData, as: UTF8.self)
                return [
                    LoadedDocument(
                        title: filename,
                        content: formatted,
                        sourceURL: metadata["sourceURL"],
                        mimeType: "application/json",
                        fileExtension: "json",
                        pages: [DocumentPage(pageNumber: 1, content: formatted)],
                        metadata: metadata
                    )
                ]
            }
        }

        // CSV / TSV handling
        let delimiter = ext == "tsv" ? "\t" : ","
        let lines = rawText.components(separatedBy: .newlines).filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        guard let header = lines.first else {
            return [LoadedDocument(title: filename, content: rawText, fileExtension: ext)]
        }

        let columns = header.components(separatedBy: delimiter).map { $0.trimmingCharacters(in: CharacterSet(charactersIn: "\" ")) }
        var semanticRows: [String] = []

        for line in lines.dropFirst() {
            let values = line.components(separatedBy: delimiter).map { $0.trimmingCharacters(in: CharacterSet(charactersIn: "\" ")) }
            var rowSegments: [String] = []
            for (idx, val) in values.enumerated() {
                let colName = idx < columns.count ? columns[idx] : "Field\(idx)"
                rowSegments.append("\(colName): \(val)")
            }
            semanticRows.append(rowSegments.joined(separator: " | "))
        }

        let combined = semanticRows.joined(separator: "\n")
        return [
            LoadedDocument(
                title: filename,
                content: combined,
                sourceURL: metadata["sourceURL"],
                mimeType: "text/csv",
                fileExtension: ext,
                pages: [DocumentPage(pageNumber: 1, content: combined)],
                sectionHeadings: columns,
                metadata: metadata
            )
        ]
    }
}

// MARK: - Apple Notes & Mail Export Loader

public struct AppleNotesExportLoader: DocumentLoader {
    public let supportedExtensions: [String] = ["note", "notes", "eml", "msg"]

    public init() {}

    public func load(from url: URL) async throws -> [LoadedDocument] {
        let text = try String(contentsOf: url, encoding: .utf8)
        return try await load(data: Data(text.utf8), filename: url.lastPathComponent, metadata: ["sourceURL": url.absoluteString])
    }

    public func load(data: Data, filename: String, metadata: [String: String]) async throws -> [LoadedDocument] {
        let raw = String(decoding: data, as: UTF8.self)
        // Clean basic HTML markup if from Apple Notes export
        let cleaned = raw
            .replacingOccurrences(of: "<[^>]+>", with: " ", options: .regularExpression)
            .replacingOccurrences(of: "&nbsp;", with: " ")
            .replacingOccurrences(of: "&amp;", with: "&")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        return [
            LoadedDocument(
                title: (filename as NSString).deletingPathExtension,
                content: cleaned,
                sourceURL: metadata["sourceURL"],
                mimeType: "text/plain",
                fileExtension: (filename as NSString).pathExtension.lowercased(),
                pages: [DocumentPage(pageNumber: 1, content: cleaned)],
                metadata: metadata
            )
        ]
    }
}

// MARK: - Apple PDFKit Loader

public struct PDFDocumentLoader: DocumentLoader {
    public let supportedExtensions: [String] = ["pdf"]

    public init() {}

    public func load(from url: URL) async throws -> [LoadedDocument] {
        #if canImport(PDFKit)
        guard let pdfDoc = PDFDocument(url: url) else {
            throw NSError(domain: "PDFDocumentLoader", code: 400, userInfo: [NSLocalizedDescriptionKey: "Failed to open PDF at \(url.path)."])
        }
        return parse(pdf: pdfDoc, title: url.deletingPathExtension().lastPathComponent, sourceURL: url.absoluteString)
        #else
        throw NSError(domain: "PDFDocumentLoader", code: 501, userInfo: [NSLocalizedDescriptionKey: "PDFKit is unavailable on this platform."])
        #endif
    }

    public func load(data: Data, filename: String, metadata: [String: String]) async throws -> [LoadedDocument] {
        #if canImport(PDFKit)
        guard let pdfDoc = PDFDocument(data: data) else {
            throw NSError(domain: "PDFDocumentLoader", code: 400, userInfo: [NSLocalizedDescriptionKey: "Failed to decode PDF data for \(filename)."])
        }
        let title = (filename as NSString).deletingPathExtension
        return parse(pdf: pdfDoc, title: title, sourceURL: metadata["sourceURL"])
        #else
        throw NSError(domain: "PDFDocumentLoader", code: 501, userInfo: [NSLocalizedDescriptionKey: "PDFKit is unavailable on this platform."])
        #endif
    }

    #if canImport(PDFKit)
    private func parse(pdf: PDFDocument, title: String, sourceURL: String?) -> [LoadedDocument] {
        var pages: [DocumentPage] = []
        var fullText = ""

        for i in 0..<pdf.pageCount {
            if let page = pdf.page(at: i), let str = page.string {
                let clean = str.trimmingCharacters(in: .whitespacesAndNewlines)
                pages.append(DocumentPage(pageNumber: i + 1, content: clean))
                fullText += "--- Page \(i + 1) ---\n" + clean + "\n\n"
            }
        }

        return [
            LoadedDocument(
                title: title,
                content: fullText.trimmingCharacters(in: .whitespacesAndNewlines),
                sourceURL: sourceURL,
                mimeType: "application/pdf",
                fileExtension: "pdf",
                pages: pages,
                metadata: ["pageCount": "\(pdf.pageCount)"]
            )
        ]
    }
    #endif
}

// MARK: - Auto Universal Document Loader

public struct AutoDocumentLoader: DocumentLoader {
    private let loaders: [any DocumentLoader]

    public var supportedExtensions: [String] {
        loaders.flatMap(\.supportedExtensions)
    }

    public init(loaders: [any DocumentLoader] = [
        PDFDocumentLoader(),
        MarkdownDocumentLoader(),
        CodeDocumentLoader(),
        StructuredDataDocumentLoader(),
        AppleNotesExportLoader(),
        PlainTextDocumentLoader()
    ]) {
        self.loaders = loaders
    }

    public func load(from url: URL) async throws -> [LoadedDocument] {
        let ext = url.pathExtension.lowercased()
        for loader in loaders {
            if loader.supportedExtensions.contains(ext) {
                return try await loader.load(from: url)
            }
        }
        return try await PlainTextDocumentLoader().load(from: url)
    }

    public func load(data: Data, filename: String, metadata: [String: String]) async throws -> [LoadedDocument] {
        let ext = (filename as NSString).pathExtension.lowercased()
        for loader in loaders {
            if loader.supportedExtensions.contains(ext) {
                return try await loader.load(data: data, filename: filename, metadata: metadata)
            }
        }
        return try await PlainTextDocumentLoader().load(data: data, filename: filename, metadata: metadata)
    }
}
