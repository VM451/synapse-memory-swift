import Testing
import Foundation
@testable import SynapseMemory

@Suite("CloudKit Sync Integration Tests")
struct CloudKitSyncTests {
    
    @Test("MemoryItem to CKRecord serialization roundtrip")
    func testCKRecordRoundtrip() {
        let item = MemoryItem(
            memory: "User loves Swift 6 concurrency",
            hash: "hash_123",
            vector: [0.1, 0.2, 0.3],
            userId: "user_777",
            agentId: "agent_mem",
            metadata: ["source": "unit_test"]
        )

        let zoneID = CKRecordZone.ID(zoneName: "SynapsePrivateZone", ownerName: CKCurrentUserDefaultName)
        let record = item.toCKRecord(zoneID: zoneID)
        #expect(record.recordID.recordName == item.id.uuidString)
        #expect(record["memory"] as? String == "User loves Swift 6 concurrency")

        let decoded = MemoryItem.fromCKRecord(record)
        #expect(decoded != nil)
        #expect(decoded?.id == item.id)
        #expect(decoded?.memory == item.memory)
        #expect(decoded?.userId == item.userId)
        #expect(decoded?.metadata == item.metadata)
    }

    @Test("Last-Write-Wins conflict resolution prefers higher scalar version")
    func testConflictResolutionVersion() {
        let engine = CloudKitSyncEngine(containerId: "iCloud.com.synapse.test")
        let now = Date()

        let local = MemoryItem(memory: "Version 1 text", updatedAt: now, version: 1)
        let remote = MemoryItem(memory: "Version 2 text", updatedAt: now.addingTimeInterval(-10), version: 2)

        let winner = engine.resolveConflicts(local: local, remote: remote)
        #expect(winner.memory == "Version 2 text")
    }
}

import CloudKit
