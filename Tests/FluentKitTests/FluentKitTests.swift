@testable import FluentKit
@testable import FluentBenchmark
import XCTest
import Foundation

final class FluentKitTests: XCTestCase {
    func testMigrationLogNames() throws {
        XCTAssertEqual(MigrationLog.reference.$id.name, "id")
        XCTAssertEqual(MigrationLog.reference.$name.name, "name")
        XCTAssertEqual(MigrationLog.reference.$batch.name, "batch")
        XCTAssertEqual(MigrationLog.reference.$createdAt.name, "created_at")
        XCTAssertEqual(MigrationLog.reference.$updatedAt.name, "updated_at")
    }

    func testGalaxyPlanetNames() throws {
        XCTAssertEqual(Galaxy.reference.$id.name, "id")
        XCTAssertEqual(Galaxy.reference.$name.name, "name")
        XCTAssertEqual(Galaxy.reference.$planets.idField.name, "galaxy_id")


        let galaxy = Galaxy(id: 1, name: "Milky Way")
        // test json encoding

        XCTAssertEqual(Planet.reference.$id.name, "id")
        XCTAssertEqual(Planet.reference.$name.name, "name")
        XCTAssertEqual(Planet.reference.$galaxy.idField.name, "galaxy_id")
    }
}

