import FluentSQL

extension FluentBenchmarker {
    public func testSort() throws {
        try self.testSort_basic()
        try self.testSort_sql()
    }

    private func testSort_basic() throws {
        try self.runTest(#function, [
            SolarSystem()
        ]) {
            let ascending = try Galaxy.query(on: self.database)
                .sort(\.$name, .ascending)
                .all().wait()
            let descending = try Galaxy.query(on: self.database)
                .sort(\.$name, .descending)
                .all().wait()
            XCTAssertEqual(
                ascending.map(\.name),
                descending.reversed().map(\.name)
            )
        }
    }

    private func testSort_sql() throws {
        try self.runTest(#function, [
            SolarSystem()
        ]) {
            guard self.database is SQLDatabase else {
                self.database.logger.warning("Skipping \(#function)")
                return
            }

            let planets = try Planet.query(on: self.database)
                .sort(.sql("name", .notEqual, "Earth"))
                .all().wait()
            XCTAssertEqual(planets.first?.name, "Earth")
        }
    }
}
