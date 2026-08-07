# Knowledge Graph Memory Guide

Extract, store, and query relational entity graphs locally on Apple Silicon.

## Overview

Mem0Swift includes a local Knowledge Graph memory engine inspired by graphiti and Mem0. It extracts relational triples `(Subject, Relation, Object)` from conversation turns to maintain structured relationships alongside dense vector embeddings.

### Triples & Graph Architecture

- **`Entity`**: A discrete named node representing a person, location, preference, skill, or concept.
- **`Relation`**: A directed edge connecting two entities with relationship types (`lives_in`, `allergic_to`, `works_on`, `prefers`).
- **`GraphTriple`**: A flattened triple `(sourceEntityName, relationshipType, targetEntityName)` easily convertible into natural language prompt context.

### Accessing Knowledge Graph Memories

```swift
import Mem0Swift

let mem0 = try await Mem0Client(config: Mem0Config())

// 1. Extract entities and relations from conversation
let messages = [
    Message(role: .user, content: "Hi, I am Alex and I live in Bangkok.")
]
try await mem0.add(messages: messages, userId: "alex_123")

// 2. Query all extracted graph triples
let triples = try await mem0.getRelations(userId: "alex_123")
for triple in triples {
    print("\(triple.sourceEntityName) -> [\(triple.relationshipType)] -> \(triple.targetEntityName)")
}
// Prints: Alex -> [lives_in] -> Bangkok
```

### CloudKit Multi-Device Graph Sync

Knowledge graph entities and relations are automatically serialized into `Mem0Entity` and `Mem0Relation` `CKRecord` types and synchronized across the user's Apple devices using CloudKit private database subscriptions.
