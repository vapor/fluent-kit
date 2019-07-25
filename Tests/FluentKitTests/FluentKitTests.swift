@testable import FluentKit
@testable import FluentBenchmark
import XCTest
import Foundation

final class FluentKitTests: XCTestCase {
    func testMigrationLogNames() throws {
        XCTAssertEqual(MigrationLog().$id.name, "id")
        XCTAssertEqual(MigrationLog().$name.name, "name")
        XCTAssertEqual(MigrationLog().$batch.name, "batch")
        XCTAssertEqual(MigrationLog().$createdAt.name, "created_at")
        XCTAssertEqual(MigrationLog().$updatedAt.name, "updated_at")
    }

    func testGalaxyPlanetNames() throws {
        XCTAssertEqual(Galaxy().$id.name, "id")
        XCTAssertEqual(Galaxy().$name.name, "name")
        XCTAssertEqual(Galaxy().$planets.idField.name, "galaxy_id")


        let galaxy = Galaxy(id: 1, name: "Milky Way")
        // test json encoding

        XCTAssertEqual(Planet().$id.name, "id")
        XCTAssertEqual(Planet().$name.name, "name")
        XCTAssertEqual(Planet().$galaxy.idField.name, "galaxy_id")
    }
}

