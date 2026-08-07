import Foundation
import BackgroundTasks
import OSLog

/// Handler for background memory maintenance, deduplication, and decay consolidation tasks via BGTaskScheduler.
public actor SynapseBackgroundTaskHandler {
    public static let shared = SynapseBackgroundTaskHandler()
    public static let taskIdentifier = "com.synapse.memory.swift.consolidation"
    
    private let logger = Logger(subsystem: "com.synapse.memory.swift", category: "SynapseBackgroundTaskHandler")

    public init() {}

    /// Registers the background processing task identifier with BGTaskScheduler.
    public func registerTask() {
        #if os(iOS) || os(tvOS) || os(visionOS)
        BGTaskScheduler.shared.register(forTaskWithIdentifier: Self.taskIdentifier, using: nil) { task in
            guard let processingTask = task as? BGProcessingTask else { return }
            Task {
                await self.handleBackgroundConsolidation(task: processingTask)
            }
        }
        logger.info("Registered background task handler: \(Self.taskIdentifier)")
        #endif
    }

    /// Schedules a background maintenance task.
    public func scheduleBackgroundMaintenance() {
        #if os(iOS) || os(tvOS) || os(visionOS)
        let request = BGProcessingTaskRequest(identifier: Self.taskIdentifier)
        request.requiresNetworkConnectivity = false
        request.requiresExternalPower = true
        request.earliestBeginDate = Date(timeIntervalSinceNow: 6 * 3600) // Every 6 hours

        do {
            try BGTaskScheduler.shared.submit(request)
            logger.info("Successfully scheduled background consolidation task.")
        } catch {
            logger.error("Failed to submit background task: \(error.localizedDescription)")
        }
        #endif
    }

    #if os(iOS) || os(tvOS) || os(visionOS)
    private func handleBackgroundConsolidation(task: BGProcessingTask) async {
        task.expirationHandler = {
            logger.warning("Background consolidation task expired before completion.")
        }

        do {
            if let client = SynapseClient.shared {
                // Perform background CloudKit sync & consolidation pass
                try await client.sync()
            }
            task.setTaskCompleted(success: true)
            logger.info("Completed background memory consolidation task.")
        } catch {
            logger.error("Error during background consolidation: \(error.localizedDescription)")
            task.setTaskCompleted(success: false)
        }
    }
    #endif
}
