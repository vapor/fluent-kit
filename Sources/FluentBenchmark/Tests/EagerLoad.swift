extension FluentBenchmarker {
    public func testEagerLoading() throws {
        try self.runTest(#function, [
            SolarSystem()
        ]) {
            let galaxies = try Galaxy.query(on: self.database)
                .with(\.$stars) {
                    $0.with(\.$planets) {
                        $0.with(\.$moons)
                        $0.with(\.$tags)
                    }
                }
                .all().wait()

            try print(prettyJSON(galaxies))
        }
    }

    public func testEagerLoadChildren() throws {
        try self.runTest(#function, [
            SolarSystem()
        ]) {
            let galaxies = try Galaxy.query(on: self.database)
                .with(\.$stars)
                .all().wait()

            for galaxy in galaxies {
                switch galaxy.name {
                case "Milky Way":
                    XCTAssertEqual(
                        galaxy.stars.contains { $0.name == "Sun" },
                        true
                    )
                    XCTAssertEqual(
                        galaxy.stars.contains { $0.name == "Alpheratz"},
                        false
                    )
                default: break
                }
            }
        }
    }

    public func testEagerLoadParent() throws {
        try self.runTest(#function, [
            SolarSystem()
        ]) {
            let planets = try Planet.query(on: self.database)
                .with(\.$star)
                .all().wait()

            for planet in planets {
                switch planet.name {
                case "Earth":
                    XCTAssertEqual(planet.star.name, "Sun")
                case "Proxima Centauri b":
                    XCTAssertEqual(planet.star.name, "Alpha Centauri")
                default: break
                }
            }
        }
    }

    public func testEagerLoadParentJSON() throws {
        try self.runTest(#function, [
            SolarSystem()
        ]) {
            let planets = try Planet.query(on: self.database)
                .with(\.$star)
                .all().wait()

            try print(prettyJSON(planets))
        }
    }

    public func testEagerLoadChildrenJSON() throws {
        try self.runTest(#function, [
            SolarSystem()
        ]) {
            let galaxies = try Galaxy.query(on: self.database)
                .with(\.$stars)
                .all().wait()
            try print(prettyJSON(galaxies))
        }
    }

    public func testSiblingsEagerLoad() throws {
        try self.runTest(#function, [
            SolarSystem()
        ]) {
            let planets = try Planet.query(on: self.database)
                .with(\.$star)
                .with(\.$tags)
                .all().wait()

            for planet in planets {
                switch planet.name {
                case "Earth":
                    XCTAssertEqual(planet.star.name, "Sun")
                    XCTAssertEqual(planet.tags.map { $0.name }.sorted(), ["Inhabited", "Small Rocky"])
                case "Proxima Centauri b":
                    XCTAssertEqual(planet.star.name, "Alpha Centauri")
                    XCTAssertEqual(planet.tags.map { $0.name }, ["Small Rocky"])
                case "Jupiter":
                    XCTAssertEqual(planet.star.name, "Sun")
                    XCTAssertEqual(planet.tags.map { $0.name }, ["Gas Giant"])
                default: break
                }
            }
        }
    }

    // https://github.com/vapor/fluent-kit/issues/117
    public func testEmptyEagerLoadChildren() throws {
        try self.runTest(#function, [
            SolarSystem()
        ]) {
            let galaxies = try Galaxy.query(on: self.database)
                .filter(\.$name == "foo")
                .with(\.$stars)
                .all().wait()

            XCTAssertEqual(galaxies.count, 0)
        }
    }
}


func prettyJSON<T>(_ value: T) throws -> String
    where T: Encodable
{
    let encoder = JSONEncoder()
    encoder.outputFormatting = .prettyPrinted
    return try String(decoding: encoder.encode(value), as: UTF8.self)
}
