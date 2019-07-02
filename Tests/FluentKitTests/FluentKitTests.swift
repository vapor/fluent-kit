@testable import FluentKit
import FluentBenchmark
import XCTest

final class FluentKitTests: XCTestCase {
    func testMigrationLogNames() throws {
        XCTAssertEqual(MigrationLog.reference.$id.name, "id")
        XCTAssertEqual(MigrationLog.reference.$name.name, "name")
        XCTAssertEqual(MigrationLog.reference.$batch.name, "batch")
        XCTAssertEqual(MigrationLog.reference.$createdAt.name, "created_at")
        XCTAssertEqual(MigrationLog.reference.$updatedAt.name, "updated_at")
    }
}

