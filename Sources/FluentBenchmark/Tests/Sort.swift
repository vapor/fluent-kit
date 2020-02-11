extension FluentBenchmarker {
    public func testSort() throws {
        // seeded db
        try runTest(#function, [
            GalaxyMigration(),
            PlanetMigration(),
            GalaxySeed(),
            PlanetSeed()
        ]) {
            let ascending = try Galaxy.query(on: self.database).sort(\.$name, .ascending).all().wait()
            let descending = try Galaxy.query(on: self.database).sort(\.$name, .descending).all().wait()
            XCTAssertEqual(ascending.map { $0.name }, descending.reversed().map { $0.name })
        }
    }
}
