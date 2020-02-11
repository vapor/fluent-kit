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
            guard count == 26 else {
                throw Failure("Not all galaxies savied")
            }
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
                guard galaxy.name == "Foo" else {
                    throw Failure("batch update did not set id")
                }
            }
        }
    }
    
}
