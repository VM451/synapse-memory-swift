import Foundation
import CloudKit

extension MemoryItem {
    /// Convert a `MemoryItem` into a CloudKit `CKRecord`.
    public func toCKRecord(zoneID: CKRecordZone.ID) -> CKRecord {
        let recordID = CKRecord.ID(recordName: id.uuidString, zoneID: zoneID)
        let record = CKRecord(recordType: "SynapseMemory", recordID: recordID)
        
        record["memory"] = memory as CKRecordValue
        record["hash"] = hash as CKRecordValue
        
        let vectorData = Data(bytes: vector, count: vector.count * MemoryLayout<Float>.size)
        record["vectorData"] = vectorData as CKRecordValue
        
        if let userId = userId { record["userId"] = userId as CKRecordValue }
        if let agentId = agentId { record["agentId"] = agentId as CKRecordValue }
        if let runId = runId { record["runId"] = runId as CKRecordValue }
        
        if let jsonEncoder = try? JSONEncoder().encode(metadata),
           let jsonStr = String(data: jsonEncoder, encoding: .utf8) {
            record["metadataJson"] = jsonStr as CKRecordValue
        }
        
        record["validFrom"] = validFrom as CKRecordValue
        if let validTo = validTo { record["validTo"] = validTo as CKRecordValue }
        if let supersededById = supersededById { record["supersededById"] = supersededById.uuidString as CKRecordValue }
        
        record["accessCount"] = Int64(accessCount) as CKRecordValue
        record["lastAccessedAt"] = lastAccessedAt as CKRecordValue
        record["scoreWeight"] = Double(scoreWeight) as CKRecordValue
        
        record["createdAt"] = createdAt as CKRecordValue
        record["updatedAt"] = updatedAt as CKRecordValue
        record["isDeleted"] = (isDeleted ? 1 : 0) as CKRecordValue
        record["version"] = version as CKRecordValue
        
        return record
    }

    /// Decode a `MemoryItem` from a CloudKit `CKRecord`.
    public static func fromCKRecord(_ record: CKRecord) -> MemoryItem? {
        guard let id = UUID(uuidString: record.recordID.recordName),
              let memory = record["memory"] as? String
        else {
            return nil
        }

        let hash = (record["hash"] as? String) ?? computeHash(for: memory)
        
        var vector: [Float] = []
        if let vectorData = record["vectorData"] as? Data {
            vector = vectorData.withUnsafeBytes { buffer in
                Array(buffer.bindMemory(to: Float.self))
            }
        }

        var metadata: [String: String] = [:]
        if let jsonStr = record["metadataJson"] as? String,
           let data = jsonStr.data(using: .utf8),
           let decoded = try? JSONDecoder().decode([String: String].self, from: data) {
            metadata = decoded
        }

        let validFrom = (record["validFrom"] as? Date) ?? Date()
        let validTo = record["validTo"] as? Date
        let supersededStr = record["supersededById"] as? String
        let supersededById = supersededStr != nil ? UUID(uuidString: supersededStr!) : nil

        let accessCount = Int((record["accessCount"] as? Int64) ?? 0)
        let lastAccessedAt = (record["lastAccessedAt"] as? Date) ?? Date()
        let scoreWeight = Float((record["scoreWeight"] as? Double) ?? 1.0)

        let createdAt = (record["createdAt"] as? Date) ?? Date()
        let updatedAt = (record["updatedAt"] as? Date) ?? Date()
        let isDeletedInt = (record["isDeleted"] as? Int64) ?? 0
        let version = (record["version"] as? Int64) ?? 1

        return MemoryItem(
            id: id,
            memory: memory,
            hash: hash,
            vector: vector,
            userId: record["userId"] as? String,
            agentId: record["agentId"] as? String,
            runId: record["runId"] as? String,
            metadata: metadata,
            validFrom: validFrom,
            validTo: validTo,
            supersededById: supersededById,
            accessCount: accessCount,
            lastAccessedAt: lastAccessedAt,
            scoreWeight: scoreWeight,
            createdAt: createdAt,
            updatedAt: updatedAt,
            isDeleted: isDeletedInt == 1,
            version: version
        )
    }
}
