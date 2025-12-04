import FluentBenchmark
import FluentKit
import Tracing
import InMemoryTracing
import XCTest

final class TracingTests: XCTestCase {
    func testTracing() async throws {
        let db = DummyDatabaseForTestSQLSerializer()
        let tracer = InMemoryTracer()
        InstrumentationSystem.bootstrap(tracer)

        _ = try await Planet.query(on: db).sort(\.$name, .descending).all()
        let span = try XCTUnwrap(tracer.finishedSpans.first)

        XCTAssertEqual(span.attributes["db.operation.name"]?.toSpanAttribute(), "read")
        XCTAssertEqual(span.attributes["db.query.summary"]?.toSpanAttribute(), "read planets")
        XCTAssertEqual(span.attributes["db.collection.name"]?.toSpanAttribute(), "\(Planet.schema)")
    }
}
