# CloudKit Synchronization Guide

Configure multi-device private iCloud synchronization without third-party vector databases.

## Overview

`SynapseMemory` utilizes Apple CloudKit private database (`CKContainer.default().privateCloudDatabase`) inside a custom record zone (`SynapsePrivateZone`).

### Privacy First

- Memories stay strictly inside the end user's personal iCloud container.
- Developers and third parties cannot access stored user memories.
- Transmitted data is protected with TLS and encrypted at rest on Apple servers.

### Conflict Resolution Strategy

When changes occur concurrently across an iPhone and Mac:
1. **Higher Scalar Version Wins**: Items with a higher scalar `version` take precedence.
2. **Last-Write-Wins (LWW)**: Equal versions fall back to comparing modification timestamps (`updatedAt`).

### Enabling CloudKit Sync

Enable iCloud CloudKit entitlement in your Xcode App Target settings under **Signing & Capabilities** -> **iCloud** -> **CloudKit**.
