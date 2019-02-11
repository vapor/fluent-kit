import FluentKit
import FluentBenchmark
import XCTest

final class FluentTests: XCTestCase {
    func testStub() throws {
        // let test = DummyDatabase()
        // try FluentBenchmarker(database: test).testAll()
    }
    static let allTests = [
        ("testStub", testStub),
    ]
}
