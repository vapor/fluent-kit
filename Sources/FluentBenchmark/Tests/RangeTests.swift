import FluentKit
import XCTest

extension FluentBenchmarker {
    public func testRange() throws {
        try self.testRange_basic()
    }
    
    private func testRange_basic() throws {
        try self.runTest(#function, [
            SolarSystem()
        ]) {
            do {
                let planets = try Planet.query(on: self.database)
                    .range(2..<5)
                    .sort(\.$name)
                    .all().wait()
                XCTAssertEqual(planets.count, 3)
                XCTAssertEqual(planets[0].name, "Mars")
            }
            do {
                let planets = try Planet.query(on: self.database)
                    .range(...5)
                    .sort(\.$name)
                    .all().wait()
                XCTAssertEqual(planets.count, 6)
            }
            do {
                let planets = try Planet.query(on: self.database)
                    .range(..<5)
                    .sort(\.$name)
                    .all().wait()
                XCTAssertEqual(planets.count, 5)
            }
            do {
                let planets = try Planet.query(on: self.database)
                    .range(..<5)
                    .sort(\.$name)
                    .all().wait()
                XCTAssertEqual(planets.count, 5)
            }
        }
    }
}
