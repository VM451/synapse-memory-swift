# Contributing to SynapseMemory

Thank you for helping build SynapseMemory!

## Development Guidelines

1. **Swift 6 Strict Concurrency**: All code must compile cleanly with Swift 6 strict concurrency enabled (`-enable-experimental-feature StrictConcurrency`). Public types and actor facades must conform to `Sendable`.
2. **Swift Testing**: All new features must include unit, integration, or performance tests using Swift 6 native **Swift Testing** framework (`import Testing`, `@Suite`, `@Test`, `#expect`).
3. **Verification Protocol**: Always verify your changes before submitting a PR by running:
   ```bash
   swift test
   ```
4. **Documentation**: Update DocC catalog documentation in `Sources/SynapseMemory/Documentation.docc` whenever public API signatures change.
