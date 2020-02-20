extension FluentBenchmarker {
    public func testBatch() throws {
        try self.testBatch_create()
        try self.testBatch_update()
    }

    private func testBatch_create() throws {
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

    private func testBatch_update() throws {
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
