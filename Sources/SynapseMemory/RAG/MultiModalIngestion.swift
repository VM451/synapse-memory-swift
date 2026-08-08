import Foundation
#if canImport(Vision)
import Vision
#endif
#if canImport(CoreGraphics)
import CoreGraphics
#endif
#if canImport(ImageIO)
import ImageIO
#endif

/// Protocol defining multimodal and OCR image/diagram ingestion for documents.
public protocol MultiModalIngestionProvider: Sendable {
    func extractText(from imageData: Data) async throws -> String
    func extractText(from imageURL: URL) async throws -> String
}

/// On-device OCR document and image processor leveraging Apple's Vision Framework.
public struct OCRDocumentProcessor: MultiModalIngestionProvider {
    public init() {}

    public func extractText(from imageURL: URL) async throws -> String {
        let data = try Data(contentsOf: imageURL)
        return try await extractText(from: data)
    }

    public func extractText(from imageData: Data) async throws -> String {
        #if canImport(Vision) && canImport(ImageIO)
        guard let source = CGImageSourceCreateWithData(imageData as CFData, nil),
              let cgImage = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
            return "Error: Unable to decode image buffer for OCR extraction."
        }

        return try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(returning: "")
                    return
                }

                let lines = observations.compactMap { $0.topCandidates(1).first?.string }
                continuation.resume(returning: lines.joined(separator: "\n"))
            }

            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
        #else
        return "Vision framework is unavailable on this target architecture."
        #endif
    }
}
