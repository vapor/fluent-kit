extension FluentBenchmarker {
    public func testCreate() throws {
        try self.runTest(#function, [
            GalaxyMigration()
        ]) {
            let galaxy = Galaxy(name: "Messier")
            galaxy.name += " 82"
            try galaxy.save(on: self.database).wait()
            XCTAssertNotNil(galaxy.id)

            guard let fetched = try Galaxy.query(on: self.database)
                .filter(\.$name == "Messier 82")
                .first()
                .wait() else {
                    throw Failure("unexpected empty result set")
                }

            if fetched.name != galaxy.name {
                throw Failure("unexpected name: \(galaxy) \(fetched)")
            }
            if fetched.id != galaxy.id {
                throw Failure("unexpected id: \(galaxy) \(fetched)")
            }
        }
    }

    public func testRead() throws {
        try runTest(#function, [
            GalaxyMigration(),
            GalaxySeed()
        ]) {
            guard let milkyWay = try Galaxy.query(on: self.database)
                .filter(\.$name == "Milky Way")
                .first().wait()
            else {
                throw Failure("unpexected missing galaxy")
            }
            guard milkyWay.name == "Milky Way" else {
                throw Failure("unexpected name")
            }
        }
    }

    public func testUpdate() throws {
        try runTest(#function, [
            GalaxyMigration()
        ]) {
            let galaxy = Galaxy(name: "Milkey Way")
            try galaxy.save(on: self.database).wait()
            galaxy.name = "Milky Way"
            try galaxy.save(on: self.database).wait()

            // verify
            let galaxies = try Galaxy.query(on: self.database).filter(\.$name == "Milky Way").all().wait()
            guard galaxies.count == 1 else {
                throw Failure("unexpected galaxy count: \(galaxies)")
            }
            guard galaxies[0].name == "Milky Way" else {
                throw Failure("unexpected galaxy name")
            }
        }
    }

    public func testDelete() throws {
        try runTest(#function, [
            GalaxyMigration(),
        ]) {
            let galaxy = Galaxy(name: "Milky Way")
            try galaxy.save(on: self.database).wait()
            try galaxy.delete(on: self.database).wait()

            // verify
            let galaxies = try Galaxy.query(on: self.database).all().wait()
            guard galaxies.count == 0 else {
                throw Failure("unexpected galaxy count: \(galaxies)")
            }
        }
    }

    public func testAsyncCreate() throws {
        try runTest(#function, [
            GalaxyMigration()
        ]) {
            let a = Galaxy(name: "a")
            let b = Galaxy(name: "b")
            _ = try a.save(on: self.database).and(b.save(on: self.database)).wait()
            let galaxies = try Galaxy.query(on: self.database).all().wait()
            guard galaxies.count == 2 else {
                throw Failure("both galaxies did not save")
            }
        }
    }
}
