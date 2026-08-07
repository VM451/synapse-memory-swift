import Foundation
import AppIntents

/// AppIntent allowing Siri & Apple Shortcuts to search user memories.
public struct SearchMemoriesIntent: AppIntent {
    public static let title: LocalizedStringResource = "Search AI Memories"
    public static let description = IntentDescription("Searches stored AI user memories using vector similarity and keywords.")

    @Parameter(title: "Query", description: "Search query string")
    public var query: String

    @Parameter(title: "User ID", description: "Optional User Identifier filter")
    public var userId: String?

    public init() {
        self.query = ""
    }

    public init(query: String, userId: String? = nil) {
        self.query = query
        self.userId = userId
    }

    public func perform() async throws -> some IntentResult & ReturnsValue<[String]> {
        guard let client = Mem0Client.shared else {
            throw NSError(domain: "Mem0Swift.AppIntents", code: 1, userInfo: [NSLocalizedDescriptionKey: "Mem0Client shared instance not initialized"])
        }
        
        let results = try await client.search(query: query, userId: userId, limit: 5)
        let memoryTexts = results.map { "\($0.item.memory) (Score: \(String(format: "%.2f", $0.score)))" }
        return .result(value: memoryTexts)
    }
}

/// AppIntent allowing Siri & Apple Shortcuts to manually save a new memory.
public struct AddMemoryIntent: AppIntent {
    public static let title: LocalizedStringResource = "Add AI Memory"
    public static let description = IntentDescription("Stores a new factual memory item into Mem0Swift.")

    @Parameter(title: "Memory Text", description: "Text content of the memory")
    public var memoryText: String

    @Parameter(title: "User ID", description: "Optional User Identifier")
    public var userId: String?

    public init() {
        self.memoryText = ""
    }

    public init(memoryText: String, userId: String? = nil) {
        self.memoryText = memoryText
        self.userId = userId
    }

    public func perform() async throws -> some IntentResult & ReturnsValue<String> {
        guard let client = Mem0Client.shared else {
            throw NSError(domain: "Mem0Swift.AppIntents", code: 1, userInfo: [NSLocalizedDescriptionKey: "Mem0Client shared instance not initialized"])
        }
        
        let message = Message(role: .user, content: memoryText)
        let changeset = try await client.add(messages: [message], userId: userId)
        return .result(value: "Added \(changeset.affectedItems.count) memory item(s).")
    }
}
