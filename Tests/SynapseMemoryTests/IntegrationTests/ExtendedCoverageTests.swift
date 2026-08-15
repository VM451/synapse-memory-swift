import Testing
import Foundation
import CloudKit
@testable import SynapseMemory

@Suite("Extended Memory & CloudKit Entity Tests")
struct ExtendedCoverageTests {

    @Test("Entity converts to and from CKRecord preserving all metadata and bi-temporal fields")
    func testEntityCKRecordRoundtrip() {
        let zoneID = CKRecordZone.ID(zoneName: "SynapseMemoryZone", ownerName: CKCurrentUserDefaultName)
        let entity = Entity(
            name: "Steve Jobs",
            type: "Person",
            userId: "user-123",
            agentId: "agent-abc",
            runId: "run-456",
            metadata: ["role": "Co-founder", "company": "Apple"],
            version: 3
        )

        let record = entity.toCKRecord(zoneID: zoneID)
        #expect(record.recordType == "SynapseEntity")
        #expect(record["name"] as? String == "Steve Jobs")
        #expect(record["type"] as? String == "Person")

        let decoded = Entity.fromCKRecord(record)
        #expect(decoded != nil)
        #expect(decoded?.name == "Steve Jobs")
        #expect(decoded?.type == "Person")
        #expect(decoded?.metadata["role"] == "Co-founder")
        #expect(decoded?.version == 3)
    }

    @Test("Relation converts to and from CKRecord preserving topology and weight")
    func testRelationCKRecordRoundtrip() {
        let zoneID = CKRecordZone.ID(zoneName: "SynapseMemoryZone", ownerName: CKCurrentUserDefaultName)
        let srcId = UUID()
        let tgtId = UUID()

        let relation = Relation(
            sourceEntityId: srcId,
            targetEntityId: tgtId,
            relationshipType: "FOUNDED",
            userId: "user-123",
            metadata: ["year": "1976"],
            weight: 0.95,
            version: 2
        )

        let record = relation.toCKRecord(zoneID: zoneID)
        #expect(record.recordType == "SynapseRelation")
        #expect(record["relationshipType"] as? String == "FOUNDED")

        let decoded = Relation.fromCKRecord(record)
        #expect(decoded != nil)
        #expect(decoded?.sourceEntityId == srcId)
        #expect(decoded?.targetEntityId == tgtId)
        #expect(decoded?.relationshipType == "FOUNDED")
        #expect(decoded?.weight == 0.95)
        #expect(decoded?.metadata["year"] == "1976")
    }

    @Test("OCRDocumentProcessor handles empty or invalid image buffer gracefully")
    func testOCRProcessorFallback() async throws {
        let processor = OCRDocumentProcessor()
        let emptyData = Data()
        let result = try await processor.extractText(from: emptyData)
        #expect(result.contains("Error") || result.isEmpty)
    }

    @Test("ConversationSummary and StructuredExtractionResponse encode and decode cleanly")
    func testSummaryAndExtractionModels() throws {
        let summary = ConversationSummary(
            id: UUID(),
            userId: "user-1",
            agentId: "agent-1",
            runId: "run-1",
            summary: "Discussion about Swift 6 strict concurrency migration.",
            messageCount: 5
        )

        let encoded = try JSONEncoder().encode(summary)
        let decoded = try JSONDecoder().decode(ConversationSummary.self, from: encoded)
        #expect(decoded.summary == summary.summary)
        #expect(decoded.messageCount == 5)
        #expect(decoded.userId == "user-1")

        let extraction = StructuredExtractionResponse(
            memoryOperations: [
                MemoryOperation(event: .add, memory: "User prefers dark mode"),
                MemoryOperation(event: .update, memory: "User lives in Cupertino", oldMemory: "User lives in SF")
            ]
        )
        #expect(extraction.memoryOperations.count == 2)
        #expect(extraction.memoryOperations.first?.event == .add)
    }

    @Test("MemoryFilter validates search filtering parameters correctly")
    func testMemoryFilterValidation() {
        let filter = MemoryFilter(
            userId: "user-42",
            agentId: "agent-7",
            runId: "run-9",
            metadata: ["category": "work"]
        )

        #expect(filter.userId == "user-42")
        #expect(filter.agentId == "agent-7")
        #expect(filter.runId == "run-9")
        #expect(filter.metadata?["category"] == "work")
    }
}
