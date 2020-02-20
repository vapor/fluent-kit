extension FluentBenchmarker {
    public func testBatchCreate() throws {
        try runTest(#function, [
            GalaxyMigration()
        ]) {
            let galaxies = Array("abcdefghijklmnopqrstuvwxyz").map { letter in
                return Galaxy(name: .init(letter))
            }

            try galaxies.create(on: self.database).wait()
            let count = try Galaxy.query(on: self.database).count().wait()
            XCTAssertEqual(count, 26)
        }
    }

    public func testBatchUpdate() throws {
        try runTest(#function, [
            GalaxyMigration(),
            GalaxySeed()
        ]) {
            try Galaxy.query(on: self.database).set(\.$name, to: "Foo")
                .update().wait()

            let galaxies = try Galaxy.query(on: self.database).all().wait()
            for galaxy in galaxies {
                XCTAssertEqual(galaxy.name, "Foo")
            }
        }
    }
    
}
