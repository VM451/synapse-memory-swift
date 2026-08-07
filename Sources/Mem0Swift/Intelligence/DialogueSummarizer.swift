import Foundation

/// Compresses conversation turns into rolling dialogue summaries for context-window optimization (inspired by Zep).
public actor DialogueSummarizer {
    private let llmProvider: LLMProvider

    public init(llmProvider: LLMProvider) {
        self.llmProvider = llmProvider
    }

    /// Generates or updates a rolling dialogue summary given new messages and optional prior summary.
    public func summarize(
        messages: [Message],
        priorSummary: String? = nil
    ) async throws -> String {
        guard !messages.isEmpty else {
            return priorSummary ?? ""
        }

        let newDialogue = messages.map { "\($0.role.rawValue.capitalized): \($0.content)" }.joined(separator: "\n")
        let prompt: String
        if let prior = priorSummary, !prior.isEmpty {
            prompt = """
            Progressively summarize the conversation so far, integrating the new dialogue into the existing summary.
            
            Existing Summary:
            \(prior)
            
            New Dialogue Turns:
            \(newDialogue)
            
            Provide a concise, factual summary capturing all key user decisions, preferences, and context.
            """
        } else {
            prompt = """
            Provide a concise, dense summary of the following conversation turns:
            
            Dialogue:
            \(newDialogue)
            """
        }

        struct SummaryResponse: Codable, Sendable {
            let summary: String?
        }

        if let response = try? await llmProvider.generateStructuredOutput(prompt: prompt, responseSchema: SummaryResponse.self),
           let text = response.summary, !text.isEmpty {
            return text
        }

        // Fallback local extractive summary
        return "Summary of \(messages.count) conversation turns: " + messages.prefix(3).map { $0.content }.joined(separator: "; ")
    }
}
