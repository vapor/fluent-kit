@testable import FluentKit
@testable import FluentBenchmark
import XCTest
import Foundation
import XCTFluent
import NIO

final class QueryBuilderTests: XCTestCase {
    func testFirstEmptyResult() throws {
        let test = ArrayTestDatabase()
        test.append([])

        let retrievedPlanet = try Planet.query(on: test.db).first().wait()

        XCTAssertNil(retrievedPlanet)
    }

    func testFirstSingleResult() throws {
        let planet = Planet(id: UUID(), name: "Tully")
        let test = ArrayTestDatabase()
        test.append([
            TestOutput([
                "id": planet.id as Any,
                "name": planet.name,
                "star_id": UUID()
            ])
        ])

        let retrievedPlanet = try Planet.query(on: test.db).first().wait()

        XCTAssertEqual(planet.id, retrievedPlanet?.id)
        XCTAssertEqual(planet.name, retrievedPlanet?.name)
    }

    func testFirstManyResults() throws {
        let planet = Planet(id: UUID(), name: "Tully")
        let test = ArrayTestDatabase()
        test.append([
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

        let retrievedPlanet = try Planet.query(on: test.db).first().wait()

        XCTAssertEqual(planet.id, retrievedPlanet?.id)
        XCTAssertEqual(planet.name, retrievedPlanet?.name)
    }

    func testAllManyResults() throws {
        let starId = UUID()
        let planets = [
            Planet(id: UUID(), name: "P1", starId: starId),
            Planet(id: UUID(), name: "P2", starId: starId),
            Planet(id: UUID(), name: "P3", starId: starId)
        ]
        let test = ArrayTestDatabase()
        test.append(planets.map(TestOutput.init))

        let retrievedPlanets = try Planet.query(on: test.db).all().wait()

        XCTAssertEqual(retrievedPlanets.count, planets.count)
        XCTAssertEqual(retrievedPlanets.map(\.name), planets.map(\.name))
    }

    func testQueryHistory() throws {
        let starId = UUID()
        let planets = [
            Planet(id: UUID(), name: "P1", starId: starId),
            Planet(id: UUID(), name: "P2", starId: starId),
            Planet(id: UUID(), name: "P3", starId: starId)
        ]
        let test = ArrayTestDatabase()
        let db = test.database(context: .init(configuration: test.configuration, logger: test.db.logger, eventLoop: test.db.eventLoop, history: .init()))
        test.append(planets.map(TestOutput.init))

        let retrievedPlanets = try Planet.query(on: db).all().wait()
        XCTAssertEqual(retrievedPlanets.count, planets.count)
        XCTAssertEqual(db.history?.queries.count, 1)
        XCTAssertEqual(db.history?.queries.first?.schema, Planet.schema)
    }
}
