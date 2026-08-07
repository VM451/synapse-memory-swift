# Getting Started with Mem0Swift

Integrate persistent user memory into your iOS, macOS, visionOS, or watchOS AI app in 5 minutes.

## Overview

Mem0Swift makes it simple to store, retrieve, update, and deduplicate conversational user context.

### 1. Add SPM Dependency

Add `Mem0Swift` to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/mem0ai/mem0-swift.git", from: "1.0.0")
]
```

### 2. Configure & Initialize Mem0Client

```swift
import Mem0Swift

let config = Mem0Config(
    llmProvider: OpenAIProvider(apiKey: "sk-..."),
    embeddingProvider: OpenAIEmbeddingProvider(apiKey: "sk-..."),
    enableAutoSync: true
)

let mem0 = try await Mem0Client(config: config)
```

### 3. Extract Facts from Conversation Turns

```swift
let messages = [
    Message(role: .user, content: "Hi, I live in Bangkok and I am allergic to peanuts."),
    Message(role: .assistant, content: "Got it! I will remember that you live in Bangkok and have a peanut allergy.")
]

let result = try await mem0.add(
    messages: messages,
    userId: "user_123"
)

print("Extracted Memories:", result.affectedItems.map { $0.memory })
```

### 4. Perform Hybrid Similarity Search

```swift
let searchResults = try await mem0.search(
    query: "What food should I avoid?",
    userId: "user_123",
    limit: 3
)

for item in searchResults {
    print("Found Memory:", item.item.memory, "(Score:", item.score, ")")
}
```
