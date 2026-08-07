import Foundation
import CoreSpotlight
import UniformTypeIdentifiers
import OSLog

/// Integrates stored memories into iOS/macOS Spotlight system search via CoreSpotlight framework.
public actor CoreSpotlightIndexer {
    public static let shared = CoreSpotlightIndexer()
    public static let domainIdentifier = "com.mem0.swift.memories"
    
    private let logger = Logger(subsystem: "com.mem0.swift", category: "CoreSpotlightIndexer")

    public init() {}

    /// Indexes a list of memory items into Spotlight.
    public func index(memories: [MemoryItem]) async throws {
        guard !memories.isEmpty else { return }
        
        var searchableItems: [CSSearchableItem] = []
        for item in memories {
            guard !item.isDeleted else { continue }
            
            let attributeSet = CSSearchableItemAttributeSet(contentType: .text)
            attributeSet.title = "AI Memory"
            attributeSet.contentDescription = item.memory
            attributeSet.keywords = [item.userId, item.agentId].compactMap { $0 }
            
            let searchableItem = CSSearchableItem(
                uniqueIdentifier: item.id.uuidString,
                domainIdentifier: Self.domainIdentifier,
                attributeSet: attributeSet
            )
            searchableItems.append(searchableItem)
        }

        guard !searchableItems.isEmpty else { return }

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            CSSearchableIndex.default().indexSearchableItems(searchableItems) { error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
        logger.info("Successfully indexed \(searchableItems.count) memories into Spotlight.")
    }

    /// Deletes indexed memories from Spotlight.
    public func deindex(ids: [UUID]) async throws {
        let idStrings = ids.map { $0.uuidString }
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            CSSearchableIndex.default().deleteSearchableItems(withIdentifiers: idStrings) { error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }
}
