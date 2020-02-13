extension FluentBenchmarker {
    public func testTransaction() throws {
        try self.runTest(#function, [
            SolarSystem()
        ]) {
            let result = self.database.transaction { transaction in
                Star.query(on: transaction)
                    .filter(\.$name == "Sun")
                    .first()
                    .flatMap
                { sun -> EventLoopFuture<Planet> in
                    let pluto = Planet(name: "Pluto")
                    return sun!.$planets.create(pluto, on: transaction).map {
                        pluto
                    }
                }.flatMap { pluto -> EventLoopFuture<(Planet, Tag)> in
                    let tag = Tag(name: "Dwarf")
                    return tag.create(on: transaction).map {
                        (pluto, tag)
                    }
                }.flatMap { (pluto, tag) in
                    tag.$planets.attach(pluto, on: transaction)
                }.flatMapThrowing {
                    throw Test()
                }
            }
            do {
                try result.wait()
            } catch is Test {
                // expected
            } catch {
                XCTFail("Unexpected error: \(error)")
            }

            let pluto = try Planet.query(on: self.database)
                .filter(\.$name == "Pluto")
                .first()
                .wait()
            XCTAssertNil(pluto)
        }
    }
}

private struct Test: Error { }
