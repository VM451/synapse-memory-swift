import Foundation

/// Defines standard OpenAPI / JSON Schema tool definitions and execution handlers for integrating
/// SynapseMemory seamlessly with SynapseAgent and native Apple Foundation Model tool dispatchers.
public struct SynapseMemoryAgentTools: Sendable {

    /// Returns the complete array of tool definitions for SynapseMemory as JSON Schema string.
    public static func toolsJSONSchemaString() -> String {
        """
        [
          {
            "name": "memory_search",
            "description": "Performs hybrid Accelerate SIMD vector search + SQLite FTS5 keyword search across persistent user memories.",
            "parameters": {
              "type": "object",
              "properties": {
                "query": { "type": "string", "description": "Search query or natural language question" },
                "userId": { "type": "string", "description": "Optional user identifier to scope search" },
                "limit": { "type": "integer", "description": "Max results to return (default: 5)" }
              },
              "required": ["query"]
            }
          },
          {
            "name": "memory_add",
            "description": "Extracts and stores facts, knowledge graph triples, and recall logs from conversational messages.",
            "parameters": {
              "type": "object",
              "properties": {
                "userMessage": { "type": "string", "description": "The user's statement or input" },
                "assistantMessage": { "type": "string", "description": "The assistant's reply" },
                "userId": { "type": "string", "description": "User identifier (default: 'default_user')" }
              },
              "required": ["userMessage"]
            }
          },
          {
            "name": "memory_get_relations",
            "description": "Retrieves bi-temporal knowledge graph entity-relation triples (e.g. Alex -> lives_in -> Bangkok).",
            "parameters": {
              "type": "object",
              "properties": {
                "userId": { "type": "string", "description": "User identifier to query relations for" }
              },
              "required": ["userId"]
            }
          },
          {
            "name": "memory_get_core",
            "description": "Retrieves hierarchical Letta/MemGPT-style core working memory blocks (persona/user profile).",
            "parameters": {
              "type": "object",
              "properties": {
                "userId": { "type": "string", "description": "User identifier" }
              },
              "required": ["userId"]
            }
          },
          {
            "name": "memory_set_core",
            "description": "Updates or sets a Letta/MemGPT-style core working memory block (e.g., updating user persona or preferences).",
            "parameters": {
              "type": "object",
              "properties": {
                "key": { "type": "string", "description": "Memory block key (e.g. 'persona', 'user_profile')" },
                "value": { "type": "string", "description": "Value to store in the memory block" }
              },
              "required": ["key", "value"]
            }
          },
          {
            "name": "memory_recall",
            "description": "Fetches chronological conversation history turns and recall logs for the user.",
            "parameters": {
              "type": "object",
              "properties": {
                "userId": { "type": "string", "description": "User identifier" },
                "limit": { "type": "integer", "description": "Number of turns to recall (default: 10)" }
              },
              "required": ["userId"]
            }
          },
          {
            "name": "memory_ingest",
            "description": "Ingests raw text, articles, or documentation with auto-tagging and chunking into memory.",
            "parameters": {
              "type": "object",
              "properties": {
                "content": { "type": "string", "description": "Text document or markdown content to ingest" },
                "title": { "type": "string", "description": "Document title" },
                "userId": { "type": "string", "description": "User identifier" },
                "tags": { "type": "array", "items": { "type": "string" }, "description": "Optional category tags" }
              },
              "required": ["content", "title", "userId"]
            }
          }
        ]
        """
    }

    /// Dispatches and handles tool execution against a live `SynapseClient` instance.
    public static func handleToolCall(
        client: SynapseClient,
        toolName: String,
        argumentsJSON: String
    ) async throws -> String {
        guard let data = argumentsJSON.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return "Error: Invalid JSON arguments for tool '\(toolName)'."
        }

        switch toolName {
        case "memory_search":
            guard let query = json["query"] as? String else {
                return "Error: Missing 'query' parameter."
            }
            let userId = json["userId"] as? String
            let limit = (json["limit"] as? Int) ?? 5
            let results = try await client.search(query: query, userId: userId, limit: limit)
            if results.isEmpty {
                return "No relevant memories found for '\(query)'."
            }
            return results.enumerated().map { index, r in
                "[\(index + 1)] (Score: \(String(format: "%.2f", r.score))) \(r.item.memory)"
            }.joined(separator: "\n")

        case "memory_add":
            guard let userMsg = json["userMessage"] as? String else {
                return "Error: Missing 'userMessage' parameter."
            }
            let assistantMsg = json["assistantMessage"] as? String
            let userId = (json["userId"] as? String) ?? "default_user"

            var messages = [Message(role: .user, content: userMsg)]
            if let assistantMsg = assistantMsg {
                messages.append(Message(role: .assistant, content: assistantMsg))
            }

            try await client.add(messages: messages, userId: userId)
            return "Successfully extracted and committed memories for user '\(userId)'."

        case "memory_get_relations":
            let userId = json["userId"] as? String
            let relations = try await client.getRelations(userId: userId)
            if relations.isEmpty {
                let userDesc = userId.map { " for user '\($0)'" } ?? ""
                return "No entity relations found\(userDesc)."
            }
            return relations.map { r in
                "\(r.sourceEntityName) -[\(r.relationshipType)]-> \(r.targetEntityName)"
            }.joined(separator: "\n")

        case "memory_get_core":
            let core = try await client.coreBlock
            if core.isEmpty {
                return "No core memory blocks established."
            }
            return core.map { "\($0.key):\n\($0.value)" }.joined(separator: "\n\n")

        case "memory_set_core":
            guard let key = json["key"] as? String,
                  let value = json["value"] as? String else {
                return "Error: Missing 'key' or 'value' parameter."
            }
            try await client.updateCoreBlock(key: key, value: value)
            return "Successfully updated core memory block '\(key)'."

        case "memory_recall":
            let userId = json["userId"] as? String
            let limit = (json["limit"] as? Int) ?? 10
            let history = try await client.recall(userId: userId, limit: limit)
            if history.isEmpty {
                let userDesc = userId.map { " for user '\($0)'" } ?? ""
                return "No recall history available\(userDesc)."
            }
            return history.map { item in
                "[\(item.role.rawValue.uppercased())]: \(item.content)"
            }.joined(separator: "\n")

        case "memory_ingest":
            guard let content = json["content"] as? String,
                  let title = json["title"] as? String else {
                return "Error: Missing 'content' or 'title' parameter."
            }
            let userId = (json["userId"] as? String) ?? "default_user"
            let tags = (json["tags"] as? [String]) ?? []
            try await client.ingest(content: content, title: title, userId: userId, tags: tags)
            return "Successfully ingested document '\(title)' (\(content.count) chars) for user '\(userId)'."

        default:
            return "Error: Unsupported tool '\(toolName)'."
        }
    }
}
