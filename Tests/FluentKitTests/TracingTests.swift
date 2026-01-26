#if swift(>=6.1)
import FluentBenchmark
import FluentKit
@testable import Tracing
@testable import Instrumentation
import InMemoryTracing
import Testing
import FluentSQL

@Suite("Tracing Tests")
struct TracingTests {
    let db = DummyDatabaseForTestSQLSerializer()

    init() {
        InstrumentationSystem.bootstrapInternal(TaskLocalTracer())
    }

    @Test("Tracing CRUD", .withTracing(InMemoryTracer()))
    func tracingCRUD() async throws {
        try await expectSpans(attributes: [
            .init(operation: "create", summary: "create \(Planet.schema)", collection: "\(Planet.schema)"),
            .init(operation: "read", summary: "read planets", collection: "\(Planet.schema)"),
            .init(operation: "update", summary: "update \(Planet.schema)", collection: "\(Planet.schema)"),
            .init(operation: "delete", summary: "delete \(Planet.schema)", collection: "\(Planet.schema)")
        ]) {
            // create
            let planet = Planet()
            planet.name = "Pluto"
            try await planet.create(on: db)

            // read
            _ = try await Planet.find(planet.requireID(), on: db)

            // update
            planet.name = "Jupiter"
            try await planet.update(on: db)

            // delete
            try await planet.delete(force: true, on: db)
        }
    }

    @Test("Tracing All", .withTracing(InMemoryTracer()))
    func tracingAll() async throws {
        try await expectSpan(attributes: .init(operation: "read", summary: "read \(Planet.schema)", collection: "\(Planet.schema)")) {
            _ = try await Planet.query(on: db).all()
        }
    }

    @Test("Aggregate Tracing", .withTracing(InMemoryTracer()))
    func tracingAggregates() async throws {
        db.fakedRows.append([.init(["aggregate": 1])])

        try await expectSpan(attributes: .init(
            operation: "aggregate(count(planets[id]))",
            summary: "aggregate(count(planets[id])) planets",
            collection: "\(Planet.schema)"
        )) {
            _ = try await Planet.query(on: db).count()
        }
    }

    @Test("Insert Tracing", .withTracing(InMemoryTracer()))
    func tracingInsert() async throws {
        try await expectSpan(attributes: .init(operation: "create", summary: "create \(Planet.schema)", collection: "\(Planet.schema)")) {
            try await Planet(name: "Pluto").create(on: db)
        }
    }

    @Test("Trace Getting Relations", .withTracing(InMemoryTracer()))
    func traceGettingRelations() async throws {
        try await expectSpan(attributes: .init(operation: "read", summary: "read \(Governor.schema)", collection: "\(Governor.schema)")) {
            let planet = Planet(name: "Pluto")
            try await planet.create(on: db)
            _ = try await planet.$governor.get(on: db)
        }
    }

    @Test("Trace Queries on Relations", .withTracing(InMemoryTracer()))
    func traceQueriesOnRelations() async throws {
        try await expectSpan(attributes: .init(operation: "read", summary: "read \(Moon.schema)", collection: "\(Moon.schema)")) {
            let planet = Planet(name: "Earth")
            try await planet.create(on: db)
            _ = try await planet.$moons.query(on: db).all()
        }
    }

    @Test("Trace First Query", .withTracing(InMemoryTracer()))
    func tracingFirst() async throws {
        try await expectSpan(attributes: .init(
            operation: "read", summary: "read \(Planet.schema)", collection: "\(Planet.schema)"
        )) {
            _ = try await Planet.query(on: db).first()
        }
    }

    @Test("Trace Min Aggregate", .withTracing(InMemoryTracer()))
    func tracingMin() async throws {
        db.fakedRows.append([.init(["aggregate": 100])])

        try await expectSpan(attributes: .init(
            operation: "aggregate(minimum(moons[craters]))",
            summary: "aggregate(minimum(moons[craters])) moons",
            collection: "\(Moon.schema)",
        )) {
            _ = try await Moon.query(on: db).min(\.$craters)
        }
    }

    func expectSpan(
        attributes: SpanAttributesSet,
        performing query: () async throws -> ()
    ) async throws {
        _ = try await query()

        let span = try #require(tracer.finishedSpans.last)
        attributes.check(against: span)
    }

    func expectSpans(
        attributes: [SpanAttributesSet],
        performing queries: () async throws -> ()
    ) async throws {
        _ = try await queries()

        #expect(attributes.count == tracer.finishedSpans.count, "Performed query count does not match expected attributes count")

        for (attributesSet, span) in zip(attributes, tracer.finishedSpans) {
            attributesSet.check(against: span)
        }
    }

    struct SpanAttributesSet {
        let operation: String
        let summary: String
        let collection: String
        let namespace: String? = nil

        func check(against span: FinishedInMemorySpan) {
            #expect(span.attributes["fluent.query.operation"]?.toSpanAttribute() == "\(self.operation)")
            #expect(span.attributes["fluent.query.summary"]?.toSpanAttribute() == "\(self.summary)")
            #expect(span.attributes["fluent.query.collection"]?.toSpanAttribute() == "\(self.collection)")
            if let namespace {
                #expect(span.attributes["fluent.query.namespace"]?.toSpanAttribute() == "\(namespace)")
            } else {
                #expect(span.attributes["fluent.query.namespace"]?.toSpanAttribute() == nil)
            }
        }
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
#endif
