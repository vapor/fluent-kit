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
            let galaxies = try Galaxy.query(on: self.database)
                .all().wait()

            let encoded = try JSONEncoder().encode(galaxies)
            self.database.logger.debug("\(String(decoding: encoded, as: UTF8.self)))")
            let decoded = try JSONDecoder().decode([GalaxyJSON].self, from: encoded)
            XCTAssertEqual(galaxies.map { $0.id }, decoded.map { $0.id })
            XCTAssertEqual(galaxies.map { $0.name }, decoded.map { $0.name })
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
                    XCTAssertEqual(star.name, "Sun")
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
            XCTAssertEqual(earth.star.name, "Sun")

            let test = Star(name: "Foo")
            earth.$star.value = test
            XCTAssertEqual(earth.star.name, "Foo")
            // test get uses cached value
            try XCTAssertEqual(earth.$star.get(on: self.database).wait().name, "Foo")
            // test get can reload relation
            try XCTAssertEqual(earth.$star.get(reload: true, on: self.database).wait().name, "Sun")

            // test clearing loaded relation
            earth.$star.value = nil
            XCTAssertNil(earth.$star.value)

            // test get loads relation if nil
            try XCTAssertEqual(earth.$star.get(on: self.database).wait().name, "Sun")
        }
    }
}

private struct GalaxyKey: CodingKey, ExpressibleByStringLiteral {
    var stringValue: String
    var intValue: Int? {
        return Int(self.stringValue)
    }

    init(stringLiteral value: String) {
        self.stringValue = value
    }

    init?(stringValue: String) {
        self.stringValue = stringValue
    }

    init?(intValue: Int) {
        self.stringValue = intValue.description
    }
}

private struct GalaxyJSON: Codable {
    var id: UUID
    var name: String

    init(from decoder: Decoder) throws {
        let keyed = try decoder.container(keyedBy: GalaxyKey.self)
        self.id = try keyed.decode(UUID.self, forKey: "id")
        self.name = try keyed.decode(String.self, forKey: "name")
        XCTAssertEqual(keyed.allKeys.count, 2)
    }
}
