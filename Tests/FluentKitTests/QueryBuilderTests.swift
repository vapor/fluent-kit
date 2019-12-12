@testable import FluentKit
@testable import FluentBenchmark
import XCTest
import Foundation
import FluentSQL

final class QueryBuilderTests: XCTestCase {
    func testFirstEmptyResult() throws {
        let db = DummyDatabaseForTestQueries(mockResults: [[]])

        let retrievedPlanet = try Planet.query(on: db).first().wait()

        XCTAssertNil(retrievedPlanet)
    }

    func testFirstSingleResult() throws {
        let planet = Planet(id: 10, name: "Tully", galaxyID: 1)
        let db = DummyDatabaseForTestQueries(
            mockResults: [
                [
                    DummyDatabaseForTestQueries.DummyRow(
                        dummyDecodedFields: [
                            "id": planet.id as Any,
                            "name": planet.name,
                            "galaxy_id": planet.$galaxy.id
                        ]
                    )
                ]
            ]
        )

        let retrievedPlanet = try Planet.query(on: db).first().wait()

        XCTAssertEqual(planet.id, retrievedPlanet?.id)
        XCTAssertEqual(planet.name, retrievedPlanet?.name)
        XCTAssertEqual(planet.$galaxy.id, retrievedPlanet?.$galaxy.id)
    }

    func testFirstManyResults() throws {
        let planet = Planet(id: 10, name: "Tully", galaxyID: 1)
        let db = DummyDatabaseForTestQueries(
            mockResults: [
                [
                    DummyDatabaseForTestQueries.DummyRow(
                        dummyDecodedFields: [
                            "id": planet.id as Any,
                            "name": planet.name,
                            "galaxy_id": planet.$galaxy.id
                        ]
                    ),
                    DummyDatabaseForTestQueries.DummyRow(
                        dummyDecodedFields: [
                            "id": 1,
                            "name": "Nupeter",
                            "galaxy_id": 1
                        ]
                    )
                ]
            ]
        )

        let retrievedPlanet = try Planet.query(on: db).first().wait()

        XCTAssertEqual(planet.id, retrievedPlanet?.id)
        XCTAssertEqual(planet.name, retrievedPlanet?.name)
        XCTAssertEqual(planet.$galaxy.id, retrievedPlanet?.$galaxy.id)
    }
}
