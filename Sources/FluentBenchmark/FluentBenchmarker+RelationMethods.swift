extension FluentBenchmarker {
    public func testRelationMethods() throws {
        try runTest(#function, [
            GalaxyMigration(),
            PlanetMigration(),
            GalaxySeed(),
            PlanetSeed()
        ]) {
            guard let earth = try Planet.query(on: self.database)
                .filter(\.$name == "Earth")
                .first().wait()
            else {
                throw Failure("Could not load Planet earth")
            }

            // test loading relation manually
            XCTAssertNil(earth.$galaxy.value)
            try earth.$galaxy.load(on: self.database).wait()
            XCTAssertNotNil(earth.$galaxy.value)
            XCTAssertEqual(earth.galaxy.name, "Milky Way")

            let test = Galaxy(name: "Foo")
            earth.$galaxy.value = test
            XCTAssertEqual(earth.galaxy.name, "Foo")
            // test get uses cached value
            try XCTAssertEqual(earth.$galaxy.get(on: self.database).wait().name, "Foo")
            // test get can reload relation
            try XCTAssertEqual(earth.$galaxy.get(reload: true, on: self.database).wait().name, "Milky Way")

            // test clearing loaded relation
            earth.$galaxy.value = nil
            XCTAssertNil(earth.$galaxy.value)

            // test get loads relation if nil
            try XCTAssertEqual(earth.$galaxy.get(on: self.database).wait().name, "Milky Way")
        }
    }
}
