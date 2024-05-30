import FluentKit
import Foundation
import NIOCore
import XCTest

extension FluentBenchmarker {
    public func testParent() throws {
        try self.testParent_serialization()
        try self.testParent_get()
        try self.testParent_value()
    }

    private func testParent_serialization() throws {
        try self.runTest(#function, [
            SolarSystem()
        ]) {
            let stars = try Star.query(on: self.database).all().wait()

            let encoded = try JSONEncoder().encode(stars)
            self.database.logger.trace("\(String(decoding: encoded, as: UTF8.self)))")
            let decoded = try JSONDecoder().decode([StarJSON].self, from: encoded)
            XCTAssertEqual(stars.map { $0.id }, decoded.map { $0.id })
            XCTAssertEqual(stars.map { $0.name }, decoded.map { $0.name })
            XCTAssertEqual(stars.map { $0.$galaxy.id }, decoded.map { $0.galaxy.id })
        }
    }
    
    private func testParent_get() throws {
        try self.runTest(#function, [
            SolarSystem()
        ]) {
            let planets = try Planet.query(on: self.database)
                .all().wait()

            for planet in planets {
                let star = try planet.$star.get(on: self.database).wait()
                switch planet.name {
                case "Earth", "Jupiter":
                    XCTAssertEqual(star.name, "Sol")
                case "Proxima Centauri b":
                    XCTAssertEqual(star.name, "Alpha Centauri")
                default: break
                }
            }
        }
    }

    private func testParent_value() throws {
        try runTest(#function, [
            SolarSystem()
        ]) {
            guard let earth = try Planet.query(on: self.database)
                .filter(\.$name == "Earth")
                .first().wait()
            else {
                XCTFail("Could not load Planet earth")
                return
            }

            // test loading relation manually
            XCTAssertNil(earth.$star.value)
            try earth.$star.load(on: self.database).wait()
            XCTAssertNotNil(earth.$star.value)
            XCTAssertEqual(earth.star.name, "Sol")

            let test = Star(name: "Foo")
            earth.$star.value = test
            XCTAssertEqual(earth.star.name, "Foo")
            // test get uses cached value
            try XCTAssertEqual(earth.$star.get(on: self.database).wait().name, "Foo")
            // test get can reload relation
            try XCTAssertEqual(earth.$star.get(reload: true, on: self.database).wait().name, "Sol")

            // test clearing loaded relation
            earth.$star.value = nil
            XCTAssertNil(earth.$star.value)

            // test get loads relation if nil
            try XCTAssertEqual(earth.$star.get(on: self.database).wait().name, "Sol")
        }
    }
}

private struct StarJSON: Codable {
    var id: UUID
    var name: String
    struct GalaxyJSON: Codable { var id: UUID }
    var galaxy: GalaxyJSON
}
