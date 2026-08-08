# CloudKit Multi-Device Sync Guide

SynapseMemory automatically synchronizes user memories, knowledge graph relations, and recall logs across all user Apple devices (iOS, macOS, visionOS, watchOS) using **Apple CloudKit**.

---

## 🔒 Privacy & Architecture

Unlike third-party vector databases or SaaS memory backends, SynapseMemory uses **zero servers and zero external cloud databases**:

- **Database Container**: Encrypted private iCloud database (`CKContainer.default().privateCloudDatabase`).
- **Custom Record Zone**: `SynapsePrivateZone` created automatically on first launch.
- **Data Privacy**: All memory data remains inside the user's private iCloud account. The application developer has zero access to user memories.

---

## 📦 CloudKit Record Types

The `CloudKitSyncEngine` maps local SQLite entities into four custom `CKRecord` types:

1. **`SynapseMemory`**: Vector memory items, raw text, metadata tags, bi-temporal dates (`validFrom`, `validTo`).
2. **`SynapseEntity`**: Knowledge graph entity nodes and types.
3. **`SynapseRelation`**: Knowledge graph directed edges and predicate labels.
4. **`SynapseHistory`**: Chronological recall log items.

---

## ⚡ Incremental Delta Sync Engine

`CloudKitSyncEngine` maintains offline-first resilience:

1. **Delta Change Tokens**: Uses `CKServerChangeToken` to fetch only updated or deleted records since the previous sync cycle.
2. **Offline Mutation Queue**: Modifications performed offline are queued in local SQLite and pushed upstream when network connectivity resumes.
3. **Automatic Conflict Resolution**: Conflicting record updates are resolved using last-write-wins (LWW) based on creation and modification timestamps.

---

## 💻 Configuration & Code Example

### Enabling CloudKit Sync

```swift
import SynapseMemory

// Enabled by default in SynapseConfig
let config = SynapseConfig(
    enableCloudKit: true,
    cloudKitContainerIdentifier: "iCloud.com.yourcompany.yourapp"
)

let synapse = try await SynapseClient(config: config)
```

### Manual Triggering (Optional)
CloudKit sync runs automatically in the background, but can be manually triggered if needed:

```swift
// Syncs local SQLite modifications with iCloud private CloudKit database
try await synapse.sync()
```
