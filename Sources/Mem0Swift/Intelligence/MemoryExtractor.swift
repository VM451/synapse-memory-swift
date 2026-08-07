import Foundation

/// State machine extraction engine that analyzes conversation turns against existing memory context
/// and generates structured ADD / UPDATE / DELETE / NO_CHANGE memory mutations.
public actor MemoryExtractor {
    private let vectorStore: VectorStore
    private let embeddingProvider: EmbeddingProvider
    private let llmProvider: LLMProvider

    public init(
        vectorStore: VectorStore,
        embeddingProvider: EmbeddingProvider,
        llmProvider: LLMProvider
    ) {
        self.vectorStore = vectorStore
        self.embeddingProvider = embeddingProvider
        self.llmProvider = llmProvider
    }

    /// Process incoming conversation turns and update stored memories automatically.
    public func extractAndApply(
        messages: [Message],
        userId: String? = nil,
        agentId: String? = nil,
        runId: String? = nil,
        metadata: [String: String] = [:]
    ) async throws -> MemoryChangeset {
        guard !messages.isEmpty else {
            return MemoryChangeset(changes: [], affectedItems: [])
        }

        // 1. Combine recent conversation messages for contextual lookup
        let fullConversationText = messages.map { "\($0.role.rawValue.capitalized): \($0.content)" }.joined(separator: "\n")
        let queryVector = try await embeddingProvider.embed(text: fullConversationText)

        // 2. Fetch candidate existing memories from VectorStore
        let filter = MemoryFilter(userId: userId, agentId: agentId, runId: runId)
        let candidates = try await vectorStore.search(
            query: fullConversationText,
            vector: queryVector,
            limit: 10,
            filters: filter
        )

        let candidateMemories = candidates.map { $0.item }

        // 3. Construct prompt for structured LLM extraction
        let prompt = self.buildExtractionPrompt(
            conversationText: fullConversationText,
            existingMemories: candidateMemories
        )

        // 4. Generate structured response from LLM
        let structuredResponse: StructuredExtractionResponse = try await llmProvider.generateStructuredOutput(
            prompt: prompt,
            responseSchema: StructuredExtractionResponse.self
        )

        // 5. Apply mutations locally in VectorStore
        var affectedItems: [MemoryItem] = []
        var executedOperations: [MemoryOperation] = []

        for op in structuredResponse.memoryOperations {
            switch op.event {
            case .add:
                let vector = try await embeddingProvider.embed(text: op.memory)
                var mergedMeta = metadata
                if let opMeta = op.metadata {
                    mergedMeta.merge(opMeta) { _, new in new }
                }

                let newItem = MemoryItem(
                    memory: op.memory,
                    vector: vector,
                    userId: userId,
                    agentId: agentId,
                    runId: runId,
                    metadata: mergedMeta
                )

                try await vectorStore.save(item: newItem)
                try await vectorStore.logHistory(item: MemoryHistoryItem(
                    memoryId: newItem.id,
                    action: .add,
                    newMemory: newItem.memory,
                    userId: userId
                ))
                
                affectedItems.append(newItem)
                executedOperations.append(op)

            case .update:
                guard let targetIdStr = op.id, let targetUUID = UUID(uuidString: targetIdStr) else {
                    continue
                }
                guard var existing = try await vectorStore.fetch(id: targetUUID) else {
                    continue
                }

                let newVector = try await embeddingProvider.embed(text: op.memory)
                let oldMemoryText = existing.memory

                let newVersionItem = MemoryItem(
                    id: UUID(),
                    memory: op.memory,
                    hash: MemoryItem.computeHash(for: op.memory),
                    vector: newVector,
                    userId: existing.userId ?? userId,
                    agentId: existing.agentId ?? agentId,
                    runId: existing.runId ?? runId,
                    metadata: existing.metadata.merging(op.metadata ?? [:]) { _, new in new },
                    validFrom: Date(),
                    validTo: nil,
                    supersededById: nil,
                    accessCount: existing.accessCount + 1,
                    lastAccessedAt: Date(),
                    scoreWeight: existing.scoreWeight,
                    createdAt: existing.createdAt,
                    updatedAt: Date(),
                    isDeleted: false,
                    version: existing.version + 1
                )

                // Supersede existing memory item
                existing.validTo = Date()
                existing.supersededById = newVersionItem.id
                existing.updatedAt = Date()
                
                try await vectorStore.save(item: existing)
                try await vectorStore.save(item: newVersionItem)

                try await vectorStore.logHistory(item: MemoryHistoryItem(
                    memoryId: newVersionItem.id,
                    action: .update,
                    oldMemory: oldMemoryText,
                    newMemory: newVersionItem.memory,
                    userId: userId
                ))

                affectedItems.append(newVersionItem)
                executedOperations.append(op)

            case .delete:
                guard let targetIdStr = op.id, let targetUUID = UUID(uuidString: targetIdStr) else {
                    continue
                }
                guard let existing = try await vectorStore.fetch(id: targetUUID) else {
                    continue
                }

                try await vectorStore.delete(id: targetUUID)
                try await vectorStore.logHistory(item: MemoryHistoryItem(
                    memoryId: targetUUID,
                    action: .delete,
                    oldMemory: existing.memory,
                    userId: userId
                ))

                executedOperations.append(op)

            case .noChange:
                executedOperations.append(op)
            }
        }

        return MemoryChangeset(changes: executedOperations, affectedItems: affectedItems)
    }

    private func buildExtractionPrompt(conversationText: String, existingMemories: [MemoryItem]) -> String {
        let existingListStr: String
        if existingMemories.isEmpty {
            existingListStr = "None"
        } else {
            existingListStr = existingMemories.map { "ID: \($0.id.uuidString) | Memory: \($0.memory)" }.joined(separator: "\n")
        }

        return """
        You are an intelligent memory management engine.
        Analyze the conversation below and determine what user preferences, facts, or context should be remembered, updated, or removed.

        Existing Candidate Memories:
        \(existingListStr)

        Conversation Turn:
        \(conversationText)

        Instructions:
        1. Compare facts in the conversation against Existing Candidate Memories.
        2. Output a JSON object matching this schema:
        {
          "memory_operations": [
            {
              "event": "ADD" | "UPDATE" | "DELETE" | "NO_CHANGE",
              "memory": "Extracted concise factual string",
              "id": "Target UUID string if event is UPDATE or DELETE, otherwise null",
              "oldMemory": "Previous text if updating, otherwise null"
            }
          ]
        }
        3. Do not duplicate existing memories. If a new detail refines an existing memory, emit an UPDATE operation with the target ID.
        4. If a fact contradicts a previously stated memory, emit a DELETE or UPDATE operation.
        """
    }
}
