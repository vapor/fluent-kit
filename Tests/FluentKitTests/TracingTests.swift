import FluentBenchmark
import FluentKit
@testable import Tracing
@testable import Instrumentation
import InMemoryTracing
import Testing
import FluentSQL

@Suite()
struct TracingTests {
    let db = DummyDatabaseForTestSQLSerializer()

    init() {
        InstrumentationSystem.bootstrapInternal(TaskLocalTracer())
    }

    @Test("Tracing CRUD", .withTracing(InMemoryTracer()))
    func tracingCRUD() async throws {
        let planet = Planet()
        planet.name = "Pluto"
        try await planet.create(on: db)
        var span = try #require(tracer.finishedSpans.last)
        #expect(span.attributes["fluent.query.operation"]?.toSpanAttribute() == "create")
        #expect(span.attributes["fluent.query.summary"]?.toSpanAttribute() == "create \(Planet.schema)")
        #expect(span.attributes["fluent.query.collection"]?.toSpanAttribute() == "\(Planet.schema)")
        #expect(span.attributes["fluent.query.namespace"]?.toSpanAttribute() == nil)

        _ = try await Planet.find(planet.requireID(), on: db)
        span = try #require(tracer.finishedSpans.last)
        #expect(span.attributes["fluent.query.operation"]?.toSpanAttribute() == "read")
        #expect(span.attributes["fluent.query.summary"]?.toSpanAttribute() == "read planets")
        #expect(span.attributes["fluent.query.collection"]?.toSpanAttribute() == "\(Planet.schema)")
        #expect(span.attributes["fluent.query.namespace"]?.toSpanAttribute() == nil)

        planet.name = "Jupiter"
        try await planet.update(on: db)
        span = try #require(tracer.finishedSpans.last)
        #expect(span.attributes["fluent.query.operation"]?.toSpanAttribute() == "update")
        #expect(span.attributes["fluent.query.summary"]?.toSpanAttribute() == "update \(Planet.schema)")
        #expect(span.attributes["fluent.query.collection"]?.toSpanAttribute() == "\(Planet.schema)")
        #expect(span.attributes["fluent.query.namespace"]?.toSpanAttribute() == nil)

        try await planet.delete(force: true, on: db)
        span = try #require(tracer.finishedSpans.last)
        #expect(span.attributes["fluent.query.operation"]?.toSpanAttribute() == "delete")
        #expect(span.attributes["fluent.query.summary"]?.toSpanAttribute() == "delete \(Planet.schema)")
        #expect(span.attributes["fluent.query.collection"]?.toSpanAttribute() == "\(Planet.schema)")
        #expect(span.attributes["fluent.query.namespace"]?.toSpanAttribute() == nil)
    }

    @Test("Tracing All", .withTracing(InMemoryTracer()))
    func tracingFirst() async throws {
        _ = try await Planet.query(on: db).all()
        let span = try #require(tracer.finishedSpans.last)
        #expect(span.attributes["fluent.query.operation"]?.toSpanAttribute() == "read")
        #expect(span.attributes["fluent.query.summary"]?.toSpanAttribute() == "read \(Planet.schema)")
        #expect(span.attributes["fluent.query.collection"]?.toSpanAttribute() == "\(Planet.schema)")
        #expect(span.attributes["fluent.query.namespace"]?.toSpanAttribute() == nil)
    }

    @Test("Aggregate Tracing", .withTracing(InMemoryTracer()))
    func tracingAggregates() async throws {
        db.fakedRows.append([.init(["aggregate": 1])])
        _ = try await Planet.query(on: db).count()
        let span = try #require(tracer.finishedSpans.last)
        #expect(span.attributes["fluent.query.operation"]?.toSpanAttribute() == "aggregate(count(planets[id]))")
        #expect(span.attributes["fluent.query.summary"]?.toSpanAttribute() == "aggregate(count(planets[id])) planets")
        #expect(span.attributes["fluent.query.collection"]?.toSpanAttribute() == "\(Planet.schema)")
        #expect(span.attributes["fluent.query.namespace"]?.toSpanAttribute() == nil)
    }

    @Test("CRUD Tracing", .withTracing(InMemoryTracer()))
    func tracingFindInsertRaw() async throws {
        try await Planet(name: "Pluto").create(on: db)
        _ = try await Planet.find(UUID(), on: db)
        let span = try #require(tracer.finishedSpans.last)
        #expect(span.attributes["fluent.query.operation"]?.toSpanAttribute() == "read")
        #expect(span.attributes["fluent.query.summary"]?.toSpanAttribute() == "read \(Planet.schema)")
        #expect(span.attributes["fluent.query.collection"]?.toSpanAttribute() == "\(Planet.schema)")
        #expect(span.attributes["fluent.query.namespace"]?.toSpanAttribute() == nil)
    }

    @Test("Insert Tracing", .withTracing(InMemoryTracer()))
    func tracingInsert() async throws {
        let id = UUID()
        try await Planet(id: id, name: "Pluto").create(on: db)
        let span = try #require(tracer.finishedSpans.last)
        #expect(span.attributes["fluent.query.operation"]?.toSpanAttribute() == "create")
        #expect(span.attributes["fluent.query.summary"]?.toSpanAttribute() == "create \(Planet.schema)")
        #expect(span.attributes["fluent.query.collection"]?.toSpanAttribute() == "\(Planet.schema)")
        #expect(span.attributes["fluent.query.namespace"]?.toSpanAttribute() == nil)
    }
}

@TaskLocal var tracer = InMemoryTracer()

struct TracingTaskLocalTrait: TestTrait, SuiteTrait, TestScoping {
    fileprivate let implementation: @Sendable (_ body: @Sendable () async throws -> Void) async throws -> Void

    func provideScope(for test: Test, testCase: Test.Case?, performing function: @Sendable () async throws -> Void) async throws {
        try await implementation { try await function() }
    }
}

extension Trait where Self == TracingTaskLocalTrait {
    static func withTracing(_ value: InMemoryTracer) -> Self {
        Self { body in
            try await $tracer.withValue(value) {
                try await body()
            }
        }
    }
}

struct TaskLocalTracer: Tracer {
    typealias Span = InMemoryTracer.Span

    func startSpan<Instant>(_ operationName: String, context: @autoclosure () -> ServiceContext, ofKind kind: SpanKind, at instant: @autoclosure () -> Instant, function: String, file fileID: String, line: UInt) -> Span where Instant : TracerInstant {
        tracer.startSpan(operationName, context: context(), ofKind: kind, at: instant(), function: function, file: fileID, line: line)
    }

    func extract<Carrier, Extract>(
        _ carrier: Carrier, into context: inout ServiceContextModule.ServiceContext, using extractor: Extract
    ) where Carrier == Extract.Carrier, Extract: Instrumentation.Extractor  {
        tracer.extract(carrier, into: &context, using: extractor)
    }

    func inject<Carrier, Inject>(
        _ context: ServiceContextModule.ServiceContext, into carrier: inout Carrier, using injector: Inject
    ) where Carrier == Inject.Carrier, Inject: Instrumentation.Injector {
        tracer.inject(context, into: &carrier, using: injector)
    }

    func forceFlush() {
        tracer.forceFlush()
    }
}
