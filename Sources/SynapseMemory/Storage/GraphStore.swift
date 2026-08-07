import Foundation

/// Abstract interface for storing, searching, and traversing entities and relations in the local Knowledge Graph.
public protocol GraphStore: Sendable {
    /// Save or update an entity node.
    func saveEntity(_ entity: Entity) async throws
    
    /// Fetch an entity by its exact name and optional user ID.
    func fetchEntity(name: String, userId: String?) async throws -> Entity?
    
    /// Fetch all entities matching optional filters.
    func fetchEntities(userId: String?) async throws -> [Entity]
    
    /// Save or update a relationship edge between two entities.
    func saveRelation(_ relation: Relation) async throws
    
    /// Retrieve outgoing relationships and target entities from a source entity.
    func fetchRelations(from sourceEntityId: UUID) async throws -> [(relation: Relation, target: Entity)]
    
    /// Retrieve all triples matching a user ID.
    func fetchTriples(userId: String?) async throws -> [GraphTriple]
    
    /// Delete an entity and its associated relationship edges.
    func deleteEntity(id: UUID) async throws
    
    /// Delete all graph entities and relations matching a scope.
    func deleteAll(userId: String?, agentId: String?, runId: String?) async throws
    
    /// Fetch pending CloudKit sync entities & relations.
    func fetchPendingSyncGraph() async throws -> (entities: [Entity], relations: [Relation])
    
    /// Mark graph entities and relations as synced.
    func markGraphSynced(entityIds: [UUID], relationIds: [UUID]) async throws
}
