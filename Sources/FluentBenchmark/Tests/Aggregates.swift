extension FluentBenchmarker {
    public func testAggregates() throws {
        // seeded db
        try runTest(#function, [
            GalaxyMigration(),
            PlanetMigration(),
            GalaxySeed(),
            PlanetSeed()
        ]) {
            // whole table
            let count = try Planet.query(on: self.database)
                .count().wait()
            guard count == 9 else {
                throw Failure("unexpected count: \(count)")
            }
            // filtered w/ results
            let filteredCount = try Planet.query(on: self.database)
                .filter(\.$name == "Earth")
                .count().wait()
            guard filteredCount == 1 else {
                throw Failure("unexpected count: \(filteredCount)")
            }
            // filtered empty
            let emptyCount = try Planet.query(on: self.database)
                .filter(\.$name == "Pluto")
                .count().wait()
            guard emptyCount == 0 else {
                throw Failure("unexpected count: \(emptyCount)")
            }
            // max id
            let maxID = try Planet.query(on: self.database)
                .max(\.$id).wait()
            XCTAssertNotNil(maxID)
        }
        // empty db
        try runTest(#function, [
            GalaxyMigration(),
            PlanetMigration(),
        ]) {
            // whole table
            let count = try Planet.query(on: self.database)
                .count().wait()
            guard count == 0 else {
                throw Failure("unexpected count: \(count)")
            }
            // maxid
            let maxID = try Planet.query(on: self.database)
                .max(\.$id).wait()
            // expect error?
            guard maxID == nil else {
                throw Failure("unexpected maxID: \(maxID!)")
            }
        }
    }
}
