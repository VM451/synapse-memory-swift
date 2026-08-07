import Foundation

/// Remote OpenAI API provider for generating embeddings and structured LLM outputs.
public final class OpenAIProvider: EmbeddingProvider, LLMProvider, @unchecked Sendable {
    public let apiKey: String
    public let modelName: String
    public let embeddingModelName: String
    public let vectorDimension: Int
    private let baseURL: URL

    public init(
        apiKey: String,
        modelName: String = "gpt-4o-mini",
        embeddingModelName: String = "text-embedding-3-small",
        vectorDimension: Int = 1536,
        baseURL: URL = URL(string: "https://api.openai.com/v1")!
    ) {
        self.apiKey = apiKey
        self.modelName = modelName
        self.embeddingModelName = embeddingModelName
        self.vectorDimension = vectorDimension
        self.baseURL = baseURL
    }

    // MARK: - EmbeddingProvider

    public func embed(text: String) async throws -> [Float] {
        let batchResult = try await embed(batch: [text])
        guard let first = batchResult.first else {
            throw NSError(domain: "SynapseMemory.OpenAIProvider", code: 1, userInfo: [NSLocalizedDescriptionKey: "Empty embedding response"])
        }
        return first
    }

    public func embed(batch: [String]) async throws -> [[Float]] {
        let endpoint = baseURL.appendingPathComponent("embeddings")
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "model": embeddingModelName,
            "input": batch
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw NSError(domain: "SynapseMemory.OpenAIProvider", code: 2, userInfo: [NSLocalizedDescriptionKey: "OpenAI Embeddings HTTP error"])
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let dataArray = json["data"] as? [[String: Any]]
        else {
            throw NSError(domain: "SynapseMemory.OpenAIProvider", code: 3, userInfo: [NSLocalizedDescriptionKey: "Invalid OpenAI embeddings JSON format"])
        }

        var results: [[Float]] = []
        for item in dataArray {
            if let embeddingDoubles = item["embedding"] as? [Double] {
                results.append(embeddingDoubles.map { Float($0) })
            }
        }
        return results
    }

    // MARK: - LLMProvider

    public func generateStructuredOutput<T: Decodable & Sendable>(
        prompt: String,
        responseSchema: T.Type
    ) async throws -> T {
        let endpoint = baseURL.appendingPathComponent("chat/completions")
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let messagesPayload: [[String: String]] = [
            ["role": "system", "content": "You are an AI memory manager. Respond strictly in valid JSON matching the requested structure."],
            ["role": "user", "content": prompt]
        ]

        let body: [String: Any] = [
            "model": modelName,
            "messages": messagesPayload,
            "response_format": ["type": "json_object"],
            "temperature": 0.1
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw NSError(domain: "SynapseMemory.OpenAIProvider", code: 4, userInfo: [NSLocalizedDescriptionKey: "OpenAI Chat HTTP error"])
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let firstChoice = choices.first,
              let message = firstChoice["message"] as? [String: Any],
              let contentString = message["content"] as? String,
              let contentData = contentString.data(using: .utf8)
        else {
            throw NSError(domain: "SynapseMemory.OpenAIProvider", code: 5, userInfo: [NSLocalizedDescriptionKey: "Invalid OpenAI chat completion JSON response"])
        }

        let decoder = JSONDecoder()
        return try decoder.decode(T.self, from: contentData)
    }
}
