import Testing
import Foundation
@testable import SynapseMemory

@Suite("Knowledge Graph Store Unit Tests")
struct GraphStoreTests {
    
    @Test("Save and fetch Entity node")
    func testSaveAndFetchEntity() async throws {
        let store = try LocalGraphStore(inMemory: true)
        let entity = Entity(name: "Bangkok", type: "Location", userId: "alex")
        
        try await store.saveEntity(entity)
        let fetched = try await store.fetchEntity(name: "Bangkok", userId: "alex")
        
        #expect(fetched != nil)
        #expect(fetched?.name == "Bangkok")
        #expect(fetched?.type == "Location")
    }

    @Test("Save Relation edge and fetch Triples")
    func testSaveRelationAndFetchTriples() async throws {
        let store = try LocalGraphStore(inMemory: true)
        
        let person = Entity(name: "Alex", type: "Person", userId: "alex")
        let city = Entity(name: "Bangkok", type: "Location", userId: "alex")
        
        try await store.saveEntity(person)
        try await store.saveEntity(city)

        let relation = Relation(
            sourceEntityId: person.id,
            targetEntityId: city.id,
            relationshipType: "lives_in",
            userId: "alex"
        )
        try await store.saveRelation(relation)

        let triples = try await store.fetchTriples(userId: "alex")
        #expect(triples.count == 1)
        #expect(triples.first?.sourceEntityName == "Alex")
        #expect(triples.first?.relationshipType == "lives_in")
        #expect(triples.first?.targetEntityName == "Bangkok")
    }

    @Test("Delete entity cascades and soft deletes relation edges")
    func testDeleteEntityCascade() async throws {
        let store = try LocalGraphStore(inMemory: true)
        
        let person = Entity(name: "Alex", type: "Person", userId: "u1")
        let coffee = Entity(name: "Espresso", type: "Beverage", userId: "u1")
        
        try await store.saveEntity(person)
        try await store.saveEntity(coffee)

        let relation = Relation(
            sourceEntityId: person.id,
            targetEntityId: coffee.id,
            relationshipType: "prefers",
            userId: "u1"
        )
        try await store.saveRelation(relation)

        try await store.deleteEntity(id: person.id)

        let entities = try await store.fetchEntities(userId: "u1")
        #expect(!entities.contains(where: { $0.id == person.id }))

        let triples = try await store.fetchTriples(userId: "u1")
        #expect(triples.isEmpty)
    }
}
