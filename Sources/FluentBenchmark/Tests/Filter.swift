extension FluentBenchmarker {
    public func testFieldFilter() throws {
        // seeded db
        try runTest(#function, [
            MoonMigration(),
            MoonSeed()
        ]) {
            // test filtering on columns
            let equalNumbers = try Moon.query(on: self.database).filter(\.$craters == \.$comets).all().wait()
            XCTAssertEqual(equalNumbers.count, 2)
            let moreCraters = try Moon.query(on: self.database).filter(\.$craters > \.$comets).all().wait()
            XCTAssertEqual(moreCraters.count, 3)
            let moreComets = try Moon.query(on: self.database).filter(\.$craters < \.$comets).all().wait()
            XCTAssertEqual(moreComets.count, 2)
        }
    }
}
