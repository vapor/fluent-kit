extension FluentBenchmarker {
    public func testBatch() throws {
        try self.testBatch_create()
        try self.testBatch_update()
        try self.testBatch_delete()
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
    
    private func testBatch_delete() throws {
        try self.runTest(#function, [
            GalaxyMigration()
        ]) {
            let galaxy1 = Galaxy(name: "Messier")
            let galaxy2 = Galaxy(name: "2")
            
            try! galaxy1.create(on: self.database).wait()
            try! galaxy2.create(on: self.database).wait()
            
            try! [galaxy1, galaxy2].delete(on: self.database).wait()
            
            let galaxies = try! Galaxy.query(on: self.database).all().wait()
            guard galaxies.count == 0 else {
                XCTFail("unexpected galaxies count")
                return
            }
        }
    }
    
}
