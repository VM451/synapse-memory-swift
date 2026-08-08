# Hybrid Search Engine Guide

SynapseMemory features a 3-layer **Hybrid Search Engine** that combines SIMD vector similarity, full-text BM25 keyword matching, and exponential time-decay recency scoring.

---

## ⚡ 3-Layer Search Fusion Architecture

```
                                [ Search Query ]
                                       │
            ┌──────────────────────────┼──────────────────────────┐
            ▼                          ▼                          ▼
  [ 1. Dense Vector ]       [ 2. Sparse BM25 ]        [ 3. Time Decay ]
  (Accelerate vDSP SIMD)     (SQLite FTS5 Tables)      (Half-life Exponential)
            │                          │                          │
            └──────────────────────────┼──────────────────────────┘
                                       ▼
                         [ Reciprocal Rank Fusion ]
                                       │
                                       ▼
                           [ Top-K Ranked Results ]
```

---

## 📐 Detailed Layer Breakdown

### Layer 1: Dense Vector Similarity (Apple `Accelerate.framework`)
- Generates high-dimensional embedding vectors for the query string.
- Calculates vector cosine similarity or dot product directly on Apple Silicon Neural Engines and GPUs via SIMD functions (`vDSP_dotpr`, `vDSP_vpyth`).
- Achieves sub-15ms search speeds across thousands of vector entries locally.

### Layer 2: Sparse BM25 Keyword Matching (SQLite FTS5)
- Executes full-text search queries against virtual SQLite FTS5 tables using the BM25 ranking algorithm.
- Ensures exact match recall for specific proper nouns, technical terms, code snippets, and IDs.

### Layer 3: Exponential Half-Life Time Decay
- Applies a recency decay multiplier to memory scores based on elapsed time:

$$\text{DecayFactor} = \exp\left(-\frac{\Delta t \cdot \ln(2)}{\text{HalfLifeDays}}\right)$$

- Configurable via `SynapseConfig(halfLifeDays:)` (default: 30 days). Recent memories receive higher scores than stale memories with identical relevance.

---

## 💻 Code Example

```swift
import SynapseMemory

let synapse = try await SynapseClient(config: SynapseConfig(halfLifeDays: 14.0))

// Hybrid search executes vector SIMD + FTS5 BM25 + Time-decay automatically
let results = try await synapse.search(
    query: "Where did Alex relocate to?",
    userId: "alex_123",
    limit: 5
)

for res in results {
    print("Memory: \(res.item.memory)")
    print("Combined Hybrid Score: \(res.score)")
}
```
