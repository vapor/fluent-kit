extension FluentBenchmarker {
    public func testSort() throws {
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
}
