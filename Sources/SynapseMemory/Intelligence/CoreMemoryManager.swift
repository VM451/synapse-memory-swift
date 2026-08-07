import Foundation

/// Working Core Memory Manager Interface (Letta / MemGPT Inspired).
public protocol CoreMemoryManager: Sendable {
    /// Retrieve all active working memory key-value blocks.
    var coreBlock: [String: String] { get async throws }
    
    /// Update or insert a core working memory block.
    func updateCoreBlock(key: String, value: String) async throws
}

/// Swift Agentic Framework Tool interface for memory operations.
public protocol MemoryAgentTool: Sendable {
    func searchMemory(query: String) async throws -> String
    func updateCoreBlock(key: String, value: String) async throws
}
