import Foundation
import CloudKit
import OSLog

/// Actor handling atomic CloudKit delta sync, push subscriptions, and multi-device state synchronization.
public actor CloudKitSyncEngine {
    public let containerId: String
    private lazy var container: CKContainer = CKContainer(identifier: containerId)
    private lazy var privateDatabase: CKDatabase = container.privateCloudDatabase
    private lazy var customZone: CKRecordZone = CKRecordZone(zoneName: Self.defaultZoneName)
    private let logger = Logger(subsystem: "com.mem0.swift", category: "CloudKitSyncEngine")
    
    public static let defaultZoneName = "Mem0PrivateZone"
    public static let subscriptionID = "mem0-db-changes"
    
    private var changeToken: CKServerChangeToken?
    
    public init(containerId: String? = nil) {
        self.containerId = (containerId != nil && !containerId!.isEmpty) ? containerId! : "iCloud.com.mem0.swift"
    }

    /// Sets up the private custom CKRecordZone and registers push notification subscriptions.
    public func setupZoneAndSubscriptions() async throws {
        do {
            _ = try await privateDatabase.save(customZone)
            logger.info("Successfully created custom CKRecordZone: \(Self.defaultZoneName)")
        } catch let error as CKError where error.code == .zoneNotFound || error.code == .serverRecordChanged {
            // Zone already exists
        } catch {
            logger.warning("Zone setup notice: \(error.localizedDescription)")
        }
        
        let subscription = CKRecordZoneSubscription(zoneID: customZone.zoneID, subscriptionID: Self.subscriptionID)
        let notificationInfo = CKSubscription.NotificationInfo()
        notificationInfo.shouldSendContentAvailable = true
        subscription.notificationInfo = notificationInfo
        
        do {
            _ = try await privateDatabase.save(subscription)
            logger.info("Successfully registered CloudKit Push Subscription.")
        } catch {
            logger.warning("Subscription registration notice: \(error.localizedDescription)")
        }
    }

    /// Upload modified or deleted memory items to CloudKit private database.
    public func upload(memories: [MemoryItem]) async throws {
        guard !memories.isEmpty else { return }
        
        let records = memories.map { $0.toCKRecord(zoneID: customZone.zoneID) }
        let operation = CKModifyRecordsOperation(recordsToSave: records, recordIDsToDelete: nil)
        operation.savePolicy = .changedKeys
        operation.qualityOfService = .userInitiated
        
        return try await withCheckedThrowingContinuation { continuation in
            operation.modifyRecordsResultBlock = { result in
                switch result {
                case .success:
                    continuation.resume()
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
            self.privateDatabase.add(operation)
        }
    }

    /// Upload modified or deleted knowledge graph entities and relations to CloudKit.
    public func uploadGraph(entities: [Entity], relations: [Relation]) async throws {
        var records: [CKRecord] = []
        records.append(contentsOf: entities.map { $0.toCKRecord(zoneID: customZone.zoneID) })
        records.append(contentsOf: relations.map { $0.toCKRecord(zoneID: customZone.zoneID) })
        
        guard !records.isEmpty else { return }
        
        let operation = CKModifyRecordsOperation(recordsToSave: records, recordIDsToDelete: nil)
        operation.savePolicy = .changedKeys
        operation.qualityOfService = .userInitiated
        
        return try await withCheckedThrowingContinuation { continuation in
            operation.modifyRecordsResultBlock = { result in
                switch result {
                case .success:
                    continuation.resume()
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
            self.privateDatabase.add(operation)
        }
    }

    /// Result structure for incremental sync fetches.
    public struct SyncFetchResult: Sendable {
        public let updatedMemories: [MemoryItem]
        public let updatedEntities: [Entity]
        public let updatedRelations: [Relation]
        public let deletedRecordIDs: [UUID]
        public let newChangeToken: CKServerChangeToken?
    }

    /// Fetch incremental delta changes from CloudKit using stored change token.
    public func fetchChanges(currentToken: CKServerChangeToken?) async throws -> SyncFetchResult {
        var updatedMemories: [MemoryItem] = []
        var updatedEntities: [Entity] = []
        var updatedRelations: [Relation] = []
        var deletedIDs: [UUID] = []
        var newServerToken: CKServerChangeToken? = currentToken

        let zoneConfig = CKFetchRecordZoneChangesOperation.ZoneConfiguration()
        zoneConfig.previousServerChangeToken = currentToken

        let operation = CKFetchRecordZoneChangesOperation(
            recordZoneIDs: [customZone.zoneID],
            configurationsByRecordZoneID: [customZone.zoneID: zoneConfig]
        )

        return try await withCheckedThrowingContinuation { continuation in
            operation.recordWasChangedBlock = { recordID, result in
                if case .success(let record) = result {
                    if record.recordType == "Mem0Memory", let memory = MemoryItem.fromCKRecord(record) {
                        updatedMemories.append(memory)
                    } else if record.recordType == "Mem0Entity", let entity = Entity.fromCKRecord(record) {
                        updatedEntities.append(entity)
                    } else if record.recordType == "Mem0Relation", let relation = Relation.fromCKRecord(record) {
                        updatedRelations.append(relation)
                    }
                }
            }

            operation.recordWithIDWasDeletedBlock = { recordID, recordType in
                if let uuid = UUID(uuidString: recordID.recordName) {
                    deletedIDs.append(uuid)
                }
            }

            operation.recordZoneFetchResultBlock = { zoneID, result in
                if case .success(let (token, _, _)) = result {
                    newServerToken = token
                }
            }

            operation.fetchRecordZoneChangesResultBlock = { result in
                switch result {
                case .success:
                    continuation.resume(returning: SyncFetchResult(
                        updatedMemories: updatedMemories,
                        updatedEntities: updatedEntities,
                        updatedRelations: updatedRelations,
                        deletedRecordIDs: deletedIDs,
                        newChangeToken: newServerToken
                    ))
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }

            self.privateDatabase.add(operation)
        }
    }

    /// Reconciles local items with incoming remote items using Last-Write-Wins (LWW) conflict resolution strategy.
    public nonisolated func resolveConflicts(local: MemoryItem, remote: MemoryItem) -> MemoryItem {
        if remote.version > local.version {
            return remote
        } else if local.version > remote.version {
            return local
        } else {
            return remote.updatedAt >= local.updatedAt ? remote : local
        }
    }

    public nonisolated func resolveEntityConflicts(local: Entity, remote: Entity) -> Entity {
        if remote.version > local.version {
            return remote
        } else if local.version > remote.version {
            return local
        } else {
            return remote.updatedAt >= local.updatedAt ? remote : local
        }
    }
}
