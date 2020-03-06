@testable import FluentKit
@testable import FluentBenchmark
import XCTest
import Foundation
import XCTFluent

final class QueryBuilderTests: XCTestCase {
    func testFirstEmptyResult() throws {
        let db = TestDatabase()
        db.append(queryResult: [])

        let retrievedPlanet = try Planet.query(on: db).first().wait()

        XCTAssertNil(retrievedPlanet)
    }

    func testFirstSingleResult() throws {
        let planet = Planet(id: UUID(), name: "Tully")
        let db = TestDatabase()
        db.append(queryResult: [
            TestOutput([
                "id": planet.id as Any,
                "name": planet.name,
                "star_id": UUID()
            ])
        ])

        let retrievedPlanet = try Planet.query(on: db).first().wait()

        XCTAssertEqual(planet.id, retrievedPlanet?.id)
        XCTAssertEqual(planet.name, retrievedPlanet?.name)
    }

    func testFirstManyResults() throws {
        let planet = Planet(id: UUID(), name: "Tully")
        let db = TestDatabase()
        db.append(queryResult: [
            TestOutput([
                "id": planet.id as Any,
                "name": planet.name,
                "star_id": UUID()
            ]),
            TestOutput([
                "id": UUID(),
                "name": "Nupeter",
                "star_id": UUID()
            ])
        ])

        let retrievedPlanet = try Planet.query(on: db).first().wait()

        XCTAssertEqual(planet.id, retrievedPlanet?.id)
        XCTAssertEqual(planet.name, retrievedPlanet?.name)
    }
}
