import Foundation
import CloudKit

extension Entity {
    /// Convert an `Entity` node to CloudKit `CKRecord`.
    public func toCKRecord(zoneID: CKRecordZone.ID) -> CKRecord {
        let recordID = CKRecord.ID(recordName: id.uuidString, zoneID: zoneID)
        let record = CKRecord(recordType: "Mem0Entity", recordID: recordID)
        
        record["name"] = name as CKRecordValue
        record["type"] = type as CKRecordValue
        
        if let userId = userId { record["userId"] = userId as CKRecordValue }
        if let agentId = agentId { record["agentId"] = agentId as CKRecordValue }
        if let runId = runId { record["runId"] = runId as CKRecordValue }
        
        if let jsonEncoder = try? JSONEncoder().encode(metadata),
           let jsonStr = String(data: jsonEncoder, encoding: .utf8) {
            record["metadataJson"] = jsonStr as CKRecordValue
        }
        
        record["createdAt"] = createdAt as CKRecordValue
        record["updatedAt"] = updatedAt as CKRecordValue
        record["isDeleted"] = (isDeleted ? 1 : 0) as CKRecordValue
        record["version"] = version as CKRecordValue
        
        return record
    }

    /// Decode an `Entity` node from CloudKit `CKRecord`.
    public static func fromCKRecord(_ record: CKRecord) -> Entity? {
        guard let id = UUID(uuidString: record.recordID.recordName),
              let name = record["name"] as? String,
              let type = record["type"] as? String
        else {
            return nil
        }

        var metadata: [String: String] = [:]
        if let jsonStr = record["metadataJson"] as? String,
           let data = jsonStr.data(using: .utf8),
           let decoded = try? JSONDecoder().decode([String: String].self, from: data) {
            metadata = decoded
        }

        let createdAt = (record["createdAt"] as? Date) ?? Date()
        let updatedAt = (record["updatedAt"] as? Date) ?? Date()
        let isDeletedInt = (record["isDeleted"] as? Int64) ?? 0
        let version = (record["version"] as? Int64) ?? 1

        return Entity(
            id: id,
            name: name,
            type: type,
            userId: record["userId"] as? String,
            agentId: record["agentId"] as? String,
            runId: record["runId"] as? String,
            metadata: metadata,
            createdAt: createdAt,
            updatedAt: updatedAt,
            isDeleted: isDeletedInt == 1,
            version: version
        )
    }
}

extension Relation {
    /// Convert a `Relation` edge to CloudKit `CKRecord`.
    public func toCKRecord(zoneID: CKRecordZone.ID) -> CKRecord {
        let recordID = CKRecord.ID(recordName: id.uuidString, zoneID: zoneID)
        let record = CKRecord(recordType: "Mem0Relation", recordID: recordID)
        
        record["sourceEntityId"] = sourceEntityId.uuidString as CKRecordValue
        record["targetEntityId"] = targetEntityId.uuidString as CKRecordValue
        record["relationshipType"] = relationshipType as CKRecordValue
        
        if let userId = userId { record["userId"] = userId as CKRecordValue }
        
        if let jsonEncoder = try? JSONEncoder().encode(metadata),
           let jsonStr = String(data: jsonEncoder, encoding: .utf8) {
            record["metadataJson"] = jsonStr as CKRecordValue
        }
        
        record["weight"] = Double(weight) as CKRecordValue
        record["createdAt"] = createdAt as CKRecordValue
        record["updatedAt"] = updatedAt as CKRecordValue
        record["isDeleted"] = (isDeleted ? 1 : 0) as CKRecordValue
        record["version"] = version as CKRecordValue
        
        return record
    }

    /// Decode a `Relation` edge from CloudKit `CKRecord`.
    public static func fromCKRecord(_ record: CKRecord) -> Relation? {
        guard let id = UUID(uuidString: record.recordID.recordName),
              let srcStr = record["sourceEntityId"] as? String,
              let srcId = UUID(uuidString: srcStr),
              let tgtStr = record["targetEntityId"] as? String,
              let tgtId = UUID(uuidString: tgtStr),
              let relType = record["relationshipType"] as? String
        else {
            return nil
        }

        var metadata: [String: String] = [:]
        if let jsonStr = record["metadataJson"] as? String,
           let data = jsonStr.data(using: .utf8),
           let decoded = try? JSONDecoder().decode([String: String].self, from: data) {
            metadata = decoded
        }

        let weight = Float((record["weight"] as? Double) ?? 1.0)
        let createdAt = (record["createdAt"] as? Date) ?? Date()
        let updatedAt = (record["updatedAt"] as? Date) ?? Date()
        let isDeletedInt = (record["isDeleted"] as? Int64) ?? 0
        let version = (record["version"] as? Int64) ?? 1

        return Relation(
            id: id,
            sourceEntityId: srcId,
            targetEntityId: tgtId,
            relationshipType: relType,
            userId: record["userId"] as? String,
            metadata: metadata,
            weight: weight,
            createdAt: createdAt,
            updatedAt: updatedAt,
            isDeleted: isDeletedInt == 1,
            version: version
        )
    }
}
