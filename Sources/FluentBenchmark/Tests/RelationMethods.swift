extension FluentBenchmarker {
    public func testRelationMethods() throws {
        try runTest(#function, [
            SolarSystem()
        ]) {
            guard let earth = try Planet.query(on: self.database)
                .filter(\.$name == "Earth")
                .first().wait()
            else {
                XCTFail("Could not load Planet earth")
                return
            }

            // test loading relation manually
            XCTAssertNil(earth.$star.value)
            try earth.$star.load(on: self.database).wait()
            XCTAssertNotNil(earth.$star.value)
            XCTAssertEqual(earth.star.name, "Sun")

            let test = Star(name: "Foo")
            earth.$star.value = test
            XCTAssertEqual(earth.star.name, "Foo")
            // test get uses cached value
            try XCTAssertEqual(earth.$star.get(on: self.database).wait().name, "Foo")
            // test get can reload relation
            try XCTAssertEqual(earth.$star.get(reload: true, on: self.database).wait().name, "Sun")

            // test clearing loaded relation
            earth.$star.value = nil
            XCTAssertNil(earth.$star.value)

            // test get loads relation if nil
            try XCTAssertEqual(earth.$star.get(on: self.database).wait().name, "Sun")
        }
    }
}
