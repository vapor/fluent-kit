import FluentBenchmark
import FluentKit
import Tracing
@testable import Instrumentation
import InMemoryTracing
import Testing
import FluentSQL

@Suite()
struct TracingTests {
    let db = DummyDatabaseForTestSQLSerializer()
    let tracer = InMemoryTracer()

    init() {
        InstrumentationSystem.bootstrapInternal(tracer)
    }

    @Test()
    func tracing() async throws {
        _ = try await Planet.query(on: db).sort(\.$name, .descending).all()
        let span = try #require(tracer.finishedSpans.first)
        #expect(span.attributes["db.operation.name"]?.toSpanAttribute() == "read")
        #expect(span.attributes["db.query.summary"]?.toSpanAttribute() == "read planets")
        #expect(span.attributes["db.collection.name"]?.toSpanAttribute() == "\(Planet.schema)")
        #expect(span.attributes["db.namespace"]?.toSpanAttribute() == nil)
    }

    @Test 
    func tracingCRUD() async throws {
        let planet = Planet()
        planet.name = "NewPlanet"
        try await planet.create(on: db)
        var span = try #require(tracer.finishedSpans.last)
        #expect(span.attributes["db.operation.name"]?.toSpanAttribute() == "create")
        #expect(span.attributes["db.query.summary"]?.toSpanAttribute() == "create \(Planet.schema)")
        #expect(span.attributes["db.collection.name"]?.toSpanAttribute() == "\(Planet.schema)")
        #expect(span.attributes["db.namespace"]?.toSpanAttribute() == nil)

        planet.name = "Renamed"
        try await planet.update(on: db)
        span = try #require(tracer.finishedSpans.last)
        #expect(span.attributes["db.operation.name"]?.toSpanAttribute() == "update")
        #expect(span.attributes["db.query.summary"]?.toSpanAttribute() == "update \(Planet.schema)")
        #expect(span.attributes["db.collection.name"]?.toSpanAttribute() == "\(Planet.schema)")
        #expect(span.attributes["db.namespace"]?.toSpanAttribute() == nil)

        planet.name = "Saved"
        try await planet.save(on: db)
        span = try #require(tracer.finishedSpans.last)
        #expect(span.attributes["db.operation.name"]?.toSpanAttribute() == "update")
        #expect(span.attributes["db.query.summary"]?.toSpanAttribute() == "update \(Planet.schema)")
        #expect(span.attributes["db.collection.name"]?.toSpanAttribute() == "\(Planet.schema)")
        #expect(span.attributes["db.namespace"]?.toSpanAttribute() == nil)

        try await planet.delete(force: true, on: db)
        span = try #require(tracer.finishedSpans.last)
        #expect(span.attributes["db.operation.name"]?.toSpanAttribute() == "delete")
        #expect(span.attributes["db.query.summary"]?.toSpanAttribute() == "delete \(Planet.schema)")
        #expect(span.attributes["db.collection.name"]?.toSpanAttribute() == "\(Planet.schema)")
        #expect(span.attributes["db.namespace"]?.toSpanAttribute() == nil)
    }

    @Test 
    func tracingAll() async throws {
        _ = try await Planet.query(on: db).all()
        let span = try #require(tracer.finishedSpans.last)
        #expect(span.attributes["db.operation.name"]?.toSpanAttribute() == "read")
        #expect(span.attributes["db.query.summary"]?.toSpanAttribute() == "read \(Planet.schema)")
        #expect(span.attributes["db.collection.name"]?.toSpanAttribute() == "\(Planet.schema)")
        #expect(span.attributes["db.namespace"]?.toSpanAttribute() == nil)
    }

    @Test
    func tracingFirst() async throws {
        _ = try await Planet.query(on: db).first()
        let span = try #require(tracer.finishedSpans.last)
        #expect(span.attributes["db.operation.name"]?.toSpanAttribute() == "read")
        #expect(span.attributes["db.query.summary"]?.toSpanAttribute() == "read \(Planet.schema)")
        #expect(span.attributes["db.collection.name"]?.toSpanAttribute() == "\(Planet.schema)")
        #expect(span.attributes["db.namespace"]?.toSpanAttribute() == nil)
    }

    @Test 
    func tracingAggregates() async throws {
        db.fakedRows.append([.init(["aggregate": 1])])
        _ = try await Planet.query(on: db).count()
        let span = try #require(tracer.finishedSpans.last)
        #expect(span.attributes["db.operation.name"]?.toSpanAttribute() == "aggregate(count(planets[id]))")
        #expect(span.attributes["db.query.summary"]?.toSpanAttribute() == "aggregate(count(planets[id])) planets")
        #expect(span.attributes["db.collection.name"]?.toSpanAttribute() == "\(Planet.schema)")
        #expect(span.attributes["db.namespace"]?.toSpanAttribute() == nil)
    }

    @Test 
    func tracingFindInsertRaw() async throws {
        try await Planet(name: "Pluto").create(on: db)
        _ = try await Planet.find(UUID(), on: db)
        let span = try #require(tracer.finishedSpans.last)
        #expect(span.attributes["db.operation.name"]?.toSpanAttribute() == "read")
        #expect(span.attributes["db.query.summary"]?.toSpanAttribute() == "read \(Planet.schema)")
        #expect(span.attributes["db.collection.name"]?.toSpanAttribute() == "\(Planet.schema)")
        #expect(span.attributes["db.namespace"]?.toSpanAttribute() == nil)
    }

    @Test 
    func tracingInsert() async throws {
        let id = UUID()
        try await Planet(id: id, name: "Pluto").create(on: db)
        let span = try #require(tracer.finishedSpans.last)
        #expect(span.attributes["db.operation.name"]?.toSpanAttribute() == "create")
        #expect(span.attributes["db.query.summary"]?.toSpanAttribute() == "create \(Planet.schema)")
        #expect(span.attributes["db.collection.name"]?.toSpanAttribute() == "\(Planet.schema)")
        #expect(span.attributes["db.namespace"]?.toSpanAttribute() == nil)
    }

    // @Test 
    // func tracingRaw() async throws {
    //     _ = try await self.db.select().columns("*").from(Planet.schema).all(decodingFluent: Planet.self)
    //     let span = try #require(tracer.finishedSpans.last)
    //     #expect(span.attributes["db.operation.name"]?.toSpanAttribute() == "read")
    //     #expect(span.attributes["db.query.summary"]?.toSpanAttribute() == "read \(Planet.schema)")
    //     #expect(span.attributes["db.collection.name"]?.toSpanAttribute() == "\(Planet.schema)")
    //     #expect(span.attributes["db.namespace"]?.toSpanAttribute() == nil)
    // }
}
