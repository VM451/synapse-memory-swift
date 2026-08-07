# Getting Started with Mem0Swift

Integrate persistent AI user memory into your Apple Intelligence app in 5 minutes.

## Overview

Mem0Swift is purpose-built for Apple Foundation Models and CloudKit. It automatically extracts, stores, retrieves, and deduplicates conversational context locally and across user devices.

### 1. Add SPM Dependency

Add `Mem0Swift` to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/VM451/mem0-swift.git", from: "1.0.0")
]
```

### 2. Zero-Configuration Initialization

By default, `Mem0Config` utilizes Apple Foundation Models for structured memory extraction and Apple CloudKit for private multi-device sync:

```swift
import Mem0Swift

// Defaults to Apple Foundation Models + CloudKit private database
let mem0 = try await Mem0Client(config: Mem0Config())
```

### 3. Extract Facts from Conversation Turns

```swift
let messages = [
    Message(role: .user, content: "Hi, I live in Bangkok and prefer dark mode."),
    Message(role: .assistant, content: "Got it! I will remember that you live in Bangkok and prefer dark mode.")
]

let result = try await mem0.add(
    messages: messages,
    userId: "user_123"
)

print("Extracted Memories:", result.affectedItems.map { $0.memory })
```

### 4. Search Relevant Context for Prompt Construction

```swift
let searchResults = try await mem0.search(
    query: "Where does the user live?",
    userId: "user_123",
    limit: 3
)

for item in searchResults {
    print("Found Memory:", item.item.memory, "(Score:", item.score, ")")
}
```
