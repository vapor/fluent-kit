import FluentSQL

extension FluentBenchmarker {
    public func testFilter(sql: Bool = true) throws {
        try self.testFilter_field()
        if sql {
            try self.testFilter_sqlValue()
        }
        try self.testFilter_group()
    }

    private func testFilter_field() throws {
        try self.runTest(#function, [
            SolarSystem()
        ]) {
            let equalNumbers = try Moon.query(on: self.database)
                .filter(\.$craters == \.$comets).all().wait()
            XCTAssertEqual(equalNumbers.count, 7)
            let moreCraters = try Moon.query(on: self.database)
                .filter(\.$craters > \.$comets).all()
                .wait()
            XCTAssertEqual(moreCraters.count, 3)
            let moreComets = try Moon.query(on: self.database)
                .filter(\.$craters < \.$comets)
                .all().wait()
            XCTAssertEqual(moreComets.count, 1)
        }
    }

    private func testFilter_sqlValue() throws {
        try self.runTest(#function, [
            SolarSystem()
        ]) {
            let moon = try Moon.query(on: self.database)
                .filter(\.$name == .sql(raw: "'Moon'"))
                .first()
                .wait()

            XCTAssertNotNil(moon)
            XCTAssertEqual(moon?.name, "Moon")
        }
    }

    private func testFilter_group() throws {
        try self.runTest(#function, [
            SolarSystem()
        ]) {
            let planets = try Planet.query(on: self.database)
                .group(.or) {
                    $0.filter(\.$name == "Earth")
                        .filter(\.$name == "Mars")
                }
                .sort(\.$name)
                .all().wait()

            switch planets.count {
            case 2:
                XCTAssertEqual(planets[0].name, "Earth")
                XCTAssertEqual(planets[1].name, "Mars")
            default:
                XCTFail("Unexpected planets count: \(planets.count)")
            }
        }
    }
}
