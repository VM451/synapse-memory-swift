# Knowledge Graph Engine Guide

SynapseMemory includes a native **Knowledge Graph Engine** (inspired by Mem0 and Graphiti) that extracts structured entity-relation-entity triples directly from natural language text.

---

## 🕸️ Concept & Structure

Knowledge graphs represent personal context as directed relational networks:

```
[ Subject Entity ] ──────( Predicate Relation )──────> [ Object Entity ]
```

### Examples of Extracted Triples:
- `Alex` ──`lives_in`──> `Bangkok`
- `Alex` ──`works_at`──> `Apple`
- `Alex` ──`knows_skill`──> `Swift 6`

---

## 💾 Local SQLite Graph Storage

Triples are stored in the local SQLite engine (`LocalGraphStore`) inside two primary tables:
1. `entities`: Unique entity tokens, type tags, and optional embeddings.
2. `relations`: Directed edges linking a `sourceEntityId` to a `targetEntityId` with a `predicate` label and confidence weight.

---

## 💻 API Usage & Code Examples

### Extracting Triples Automatically via Dialogue

```swift
import SynapseMemory

let synapse = try await SynapseClient(config: SynapseConfig())

let messages = [
    Message(role: .user, content: "Sarah is a Senior Engineer at OpenAI and she specializes in Transformer architectures."),
    Message(role: .assistant, content: "I have recorded Sarah's role and specialization.")
]

try await synapse.add(messages: messages, userId: "team_workspace")

// Query extracted relational triples
let relations = try await synapse.getRelations(userId: "team_workspace")

for relation in relations {
    print("\(relation.subject) --[\(relation.predicate)]--> \(relation.object)")
}
```

### Output:
```text
Sarah --[works_at]--> OpenAI
Sarah --[has_role]--> Senior Engineer
Sarah --[specializes_in]--> Transformer architectures
```

---

## 🔍 Querying Relations

You can query relations scoped by user ID or retrieve node connections across the graph using `getRelations(userId:)`.
