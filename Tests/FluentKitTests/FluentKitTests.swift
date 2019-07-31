@testable import FluentKit
@testable import FluentBenchmark
import XCTest
import Foundation

final class FluentKitTests: XCTestCase {
    func testMigrationLogNames() throws {
        XCTAssertEqual(MigrationLog.key(for: \.$id), "id")
        XCTAssertEqual(MigrationLog.key(for: \.$name), "name")
        XCTAssertEqual(MigrationLog.key(for: \.$batch), "batch")
        XCTAssertEqual(MigrationLog.key(for: \.$createdAt), "created_at")
        XCTAssertEqual(MigrationLog.key(for: \.$updatedAt), "updated_at")
    }

    func testGalaxyPlanetNames() throws {
        XCTAssertEqual(Galaxy.key(for: \.$id), "id")
        XCTAssertEqual(Galaxy.key(for: \.$name), "name")

        XCTAssertEqual(Planet.key(for: \.$id), "id")
        XCTAssertEqual(Planet.key(for: \.$name), "name")
        XCTAssertEqual(Planet.key(for: \.$galaxy), "galaxy_id")
    }
}
