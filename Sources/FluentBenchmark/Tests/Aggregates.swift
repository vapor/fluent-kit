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
            let maxID = try Planet.query(on: self.database)
                .max(\.$id).wait()
            XCTAssertNotNil(maxID)
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
            let maxID = try Planet.query(on: self.database)
                .max(\.$id).wait()
            // expect error?
            XCTAssertNil(maxID)
        }
    }
}
