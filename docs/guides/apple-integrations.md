# Apple Ecosystem Integrations Guide

SynapseMemory provides deep integration with Apple operating system frameworks, including **CoreSpotlight**, **AppIntents**, and **BGTaskScheduler**.

---

## 🔍 1. CoreSpotlight Integration

SynapseMemory indexes user memories directly into the iOS/macOS system Spotlight search engine via `CSSearchableIndex`.

- Users can search for stored memories, notes, and ingested bookmarks directly from the Spotlight search bar on iOS or macOS.
- Tapping a Spotlight search result launches your application directly to the relevant memory item.

```swift
import SynapseMemory

let synapse = try await SynapseClient(config: SynapseConfig())

// Memories added or ingested are indexed automatically in CoreSpotlight
try await synapse.ingest(
    content: "WWDC keynotes announced new Apple Intelligence features.",
    title: "WWDC Notes",
    userId: "user_1"
)
```

---

## 🎙️ 2. AppIntents & Siri Shortcuts Integration

SynapseMemory exposes native `AppIntent` definitions that enable users and Siri to query or store memories via voice commands, Action Button shortcuts, or the Shortcuts app.

- **QueryMemoriesIntent**: Intent for asking Siri questions about personal memories.
- **AddMemoryIntent**: Intent for dictating a new memory directly via Siri.

```swift
import AppIntents
import SynapseMemory

struct SearchMemoriesIntent: AppIntent {
    static var title: LocalizedStringResource = "Search Memories"
    
    @Parameter(title: "Query")
    var query: String
    
    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        let synapse = try await SynapseClient(config: SynapseConfig())
        let results = try await synapse.search(query: query, userId: "default_user")
        let memoryText = results.first?.item.memory ?? "No relevant memory found."
        return .result(value: memoryText)
    }
}
```

---

## 🔋 3. Background Processing (`BGTaskScheduler`)

To maintain optimal device battery life and user responsiveness, intensive background operations (such as vector re-indexing, graph consolidation, and CloudKit delta sync) are scheduled during device idle charging states using `BGProcessingTaskRequest`.

- Scheduled automatically via `BGTaskScheduler.shared.submit(...)`.
- Ensures zero UI stutter or background battery drain during active app usage.
