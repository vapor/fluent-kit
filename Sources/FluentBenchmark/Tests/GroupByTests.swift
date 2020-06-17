extension FluentBenchmarker {
    public func testGroupBy() throws {
        try self.testGroupBy_join()
    }

    private func testGroupBy_join() throws {
        try runTest(#function, [
            SolarSystem()
        ]) {
            let earth = try XCTUnwrap(Planet.query(on: self.database).filter(\.$name == "Earth").first().wait())

            let planets = try Planet.query(on: self.database)
                .join(PlanetTag.self, on: \PlanetTag.$planet.$id == \Planet.$id)
                .filter(PlanetTag.self, \.$planet.$id == earth.requireID())
                .all().wait()
            XCTAssertEqual(planets.count, 2)

            let groupedPlanets = try Planet.query(on: self.database)
                .join(PlanetTag.self, on: \PlanetTag.$planet.$id == \Planet.$id)
                .filter(PlanetTag.self, \.$planet.$id == earth.requireID())
                .group(by: \.$id)
                .all().wait()
            XCTAssertEqual(groupedPlanets.count, 1)
        }
    }
}
