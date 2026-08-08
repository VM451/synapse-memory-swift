# Conversational Memory & Extraction Guide

SynapseMemory automatically extracts unstructured conversational context into structured semantic memories and maintains a historical state machine (`ADD`, `UPDATE`, `DELETE`, `NO_CHANGE`).

---

## 🔄 Conversational Memory Pipeline

When you call `synapse.add(messages:userId:)`, the following pipeline executes:

```
[Conversational Turns] ──> [LLM Memory Extractor] ──> [State Machine Analyzer]
                                                             │
            ┌────────────────┬───────────────────────────────┤
            ▼                ▼                               ▼
       [ADD New]      [UPDATE Existing]               [DELETE Fact]
            │                │                               │
            └────────────────┼───────────────────────────────┘
                             ▼
               [Bi-Temporal Date Stamping]
                             │
                             ▼
         [SQLite Vector + CloudKit Sync Store]
```

---

## 🧠 Memory State Machine Operations

During memory extraction, incoming facts are evaluated against existing user memories:

| Action | Description | Example Input | Resulting State |
|---|---|---|---|
| **`ADD`** | Discovers a new fact not previously known. | "I recently bought a Tesla Model 3." | Creates new memory record. |
| **`UPDATE`** | Updates an existing fact with newer information. | "I sold my Tesla and bought a Rivian R1T." | Invalidates old memory (`validTo = now`), creates new memory (`validFrom = now`). |
| **`DELETE`** | Removes a fact that is explicitly contradicted or negated. | "I don't play guitar anymore." | Sets `validTo = now` or deletes record. |
| **`NO_CHANGE`** | Information is already present and up to date. | "I live in Bangkok." (Already stored) | No modification to storage. |

---

## ⏱️ Bi-Temporal Fact Superseding

SynapseMemory tracks real-world timeline changes using bi-temporal timestamps:
- `validFrom`: The date when a fact became true.
- `validTo`: The date when a fact was superseded or rendered obsolete (`nil` if currently active).

### Code Example: Conversational Turns

```swift
import SynapseMemory

let synapse = try await SynapseClient(config: SynapseConfig())

// First turn: Learn preference
let turns1 = [
    Message(role: .user, content: "I love drinking Iced Black Coffee in the morning."),
    Message(role: .assistant, content: "Got it! I will remember your coffee preference.")
]
try await synapse.add(messages: turns1, userId: "user_42")

// Later turn: Preference update
let turns2 = [
    Message(role: .user, content: "Actually, I stopped drinking coffee last week. Now I only drink Matcha Latte."),
    Message(role: .assistant, content: "Updated! I'll note that you now prefer Matcha Latte.")
]
try await synapse.add(messages: turns2, userId: "user_42")

// Search active memories
let activeMemories = try await synapse.search(query: "What morning drink does the user like?", userId: "user_42")
for item in activeMemories {
    print("Memory: \(item.item.memory)")
}
// Outputs: Memory: User drinks Matcha Latte in the morning.
```
