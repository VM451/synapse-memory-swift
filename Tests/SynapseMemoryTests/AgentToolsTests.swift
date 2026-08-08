import Testing
import Foundation
@testable import SynapseMemory

@Suite("Agent Tools & SynapseAgent Integration Tests")
struct AgentToolsTests {

    @Test("Tool definitions export valid JSON schema properties")
    func testToolDefinitionsSchema() {
        let jsonString = SynapseMemoryAgentTools.toolsJSONSchemaString()
        #expect(jsonString.contains("memory_search"))
        #expect(jsonString.contains("memory_add"))
        #expect(jsonString.contains("memory_get_relations"))
        #expect(jsonString.contains("memory_get_core"))
        #expect(jsonString.contains("memory_set_core"))
        #expect(jsonString.contains("memory_recall"))
        #expect(jsonString.contains("memory_ingest"))
    }


    @Test("handleToolCall executes memory_set_core and memory_get_core")
    func testCoreMemoryToolHandling() async throws {
        let vectorStore = try LocalVectorStore(inMemory: true)
        let graphStore = try LocalGraphStore(inMemory: true)
        let config = SynapseConfig(
            llmProvider: MockLLMProvider(),
            embeddingProvider: MockEmbeddingProvider(vectorDimension: 64),
            customVectorStore: vectorStore,
            customGraphStore: graphStore,
            enableAutoSync: false,
            enableSpotlightIndexing: false
        )
        let client = try await SynapseClient(config: config)
        let userId = "test_user_\(UUID().uuidString)"

        let setArgs = "{\"userId\": \"\(userId)\", \"key\": \"persona\", \"value\": \"Assistant Persona: Expert in Swift 6\"}"
        let setRes = try await SynapseMemoryAgentTools.handleToolCall(
            client: client,
            toolName: "memory_set_core",
            argumentsJSON: setArgs
        )
        #expect(setRes.contains("Successfully updated"))

        let getArgs = "{\"userId\": \"\(userId)\"}"
        let getRes = try await SynapseMemoryAgentTools.handleToolCall(
            client: client,
            toolName: "memory_get_core",
            argumentsJSON: getArgs
        )
        #expect(getRes.contains("persona") || getRes.contains("Assistant Persona"))
    }

    @Test("handleToolCall executes memory_add and memory_recall")
    func testMemoryAddAndRecall() async throws {
        let vectorStore = try LocalVectorStore(inMemory: true)
        let graphStore = try LocalGraphStore(inMemory: true)
        let config = SynapseConfig(
            llmProvider: MockLLMProvider(),
            embeddingProvider: MockEmbeddingProvider(vectorDimension: 64),
            customVectorStore: vectorStore,
            customGraphStore: graphStore,
            enableAutoSync: false,
            enableSpotlightIndexing: false
        )
        let client = try await SynapseClient(config: config)
        let userId = "recall_user_\(UUID().uuidString)"

        let addArgs = "{\"userId\": \"\(userId)\", \"userMessage\": \"I am living in Cupertino\", \"assistantMessage\": \"Noted!\"}"
        let addRes = try await SynapseMemoryAgentTools.handleToolCall(
            client: client,
            toolName: "memory_add",
            argumentsJSON: addArgs
        )
        #expect(addRes.contains("Successfully extracted"))

        let recallArgs = "{\"userId\": \"\(userId)\", \"limit\": 5}"
        let recallRes = try await SynapseMemoryAgentTools.handleToolCall(
            client: client,
            toolName: "memory_recall",
            argumentsJSON: recallArgs
        )
        #expect(recallRes.contains("Cupertino") || recallRes.contains("USER"))
    }

}
