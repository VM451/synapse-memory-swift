import Foundation

/// Local Ollama provider running models (e.g. Llama 3, Mistral, Gemma, Nomic-Embed) locally on Mac without external cloud hosting.
public final class OllamaProvider: EmbeddingProvider, LLMProvider, @unchecked Sendable {
    public let modelName: String
    public let embeddingModelName: String
    public let vectorDimension: Int
    private let baseURL: URL

    public init(
        modelName: String = "llama3:latest",
        embeddingModelName: String = "nomic-embed-text",
        vectorDimension: Int = 768,
        baseURL: URL = URL(string: "http://localhost:11434")!
    ) {
        self.modelName = modelName
        self.embeddingModelName = embeddingModelName
        self.vectorDimension = vectorDimension
        self.baseURL = baseURL
    }

    // MARK: - EmbeddingProvider

    public func embed(text: String) async throws -> [Float] {
        let endpoint = baseURL.appendingPathComponent("api/embeddings")
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "model": embeddingModelName,
            "prompt": text
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw NSError(domain: "Mem0Swift.OllamaProvider", code: 1, userInfo: [NSLocalizedDescriptionKey: "Ollama embedding HTTP error"])
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let embeddingDoubles = json["embedding"] as? [Double]
        else {
            throw NSError(domain: "Mem0Swift.OllamaProvider", code: 2, userInfo: [NSLocalizedDescriptionKey: "Invalid Ollama embedding JSON"])
        }

        return VectorMath.normalize(embeddingDoubles.map { Float($0) })
    }

    public func embed(batch: [String]) async throws -> [[Float]] {
        var results: [[Float]] = []
        for text in batch {
            results.append(try await embed(text: text))
        }
        return results
    }

    // MARK: - LLMProvider

    public func generateStructuredOutput<T: Decodable & Sendable>(
        prompt: String,
        responseSchema: T.Type
    ) async throws -> T {
        let endpoint = baseURL.appendingPathComponent("api/chat")
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let messagesPayload: [[String: String]] = [
            ["role": "system", "content": "You are a local AI memory manager. Respond strictly in valid JSON matching the requested structure."],
            ["role": "user", "content": prompt]
        ]

        let body: [String: Any] = [
            "model": modelName,
            "messages": messagesPayload,
            "format": "json",
            "stream": false
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw NSError(domain: "Mem0Swift.OllamaProvider", code: 3, userInfo: [NSLocalizedDescriptionKey: "Ollama chat completion HTTP error"])
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let message = json["message"] as? [String: Any],
              let contentString = message["content"] as? String,
              let contentData = contentString.data(using: .utf8)
        else {
            throw NSError(domain: "Mem0Swift.OllamaProvider", code: 4, userInfo: [NSLocalizedDescriptionKey: "Invalid Ollama chat response"])
        }

        let decoder = JSONDecoder()
        return try decoder.decode(T.self, from: contentData)
    }
}
