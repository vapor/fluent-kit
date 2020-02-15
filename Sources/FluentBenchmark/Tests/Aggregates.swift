extension FluentBenchmarker {
    public func testAggregates() throws {
        try self.runTest(#function, [
            SolarSystem()
        ]) {
            // whole table
            let count = try Planet.query(on: self.database)
                .count().wait()
            XCTAssertEqual(count, 9)

            // filtered w/ results
            let filteredCount = try Planet.query(on: self.database)
                .filter(\.$name == "Earth")
                .count().wait()
            XCTAssertEqual(filteredCount, 1)

            // filtered empty
            let emptyCount = try Planet.query(on: self.database)
                .filter(\.$name == "Pluto")
                .count().wait()
            XCTAssertEqual(emptyCount, 0)

            // max id
            let maxName = try Planet.query(on: self.database)
                .max(\.$name).wait()
            XCTAssertEqual(maxName, "Venus")

            // eager loads ignored
            let countWithEagerLoads = try Galaxy.query(on: self.database)
                .with(\.$stars)
                .count().wait()
            XCTAssertEqual(countWithEagerLoads, 4)

            // eager loads ignored again
            let maxNameWithEagerLoads = try Galaxy.query(on: self.database)
                .with(\.$stars)
                .max(\.$name).wait()
            XCTAssertEqual(maxNameWithEagerLoads, "Pinwheel Galaxy")
        }

        // empty db
        try self.runTest(#function, [
            SolarSystem(seed: false)
        ]) {
            // whole table
            let count = try Planet.query(on: self.database)
                .count().wait()
            XCTAssertEqual(count, 0)

            // maxid
            let maxName = try Planet.query(on: self.database)
                .max(\.$name).wait()
            // expect error?
            XCTAssertNil(maxName)
        }
    }
}
