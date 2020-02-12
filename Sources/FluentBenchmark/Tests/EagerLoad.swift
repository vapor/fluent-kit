extension FluentBenchmarker {
    public func testEagerLoading() throws {
        try self.runTest(#function, [
            SolarSystem()
        ]) {
            let galaxies = try Galaxy.query(on: self.database)
                ._with(\.$stars) {
                    $0._with(\.$planets) {
                        $0._with(\.$moons)
                        $0._with(\.$tags)
                    }
                }
                .all().wait()
            let json = JSONEncoder()
            json.outputFormatting = .prettyPrinted
            try print(String(decoding: json.encode(galaxies), as: UTF8.self))
            print(galaxies)
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
            struct PlanetJSON: Codable, Equatable {
                var id: UUID
                var name: String
                var star: StarJSON

                init(name: String, star: StarJSON, on database: Database) throws {
                    self.id = try Planet.query(on: database)
                        .filter(\.$name == name)
                        .first().wait()!
                        .requireID()
                    self.name = name
                    self.star = star
                }
            }
            struct StarJSON: Codable, Equatable {
                var id: UUID
                var name: String

                init(name: String, on database: Database) throws {
                    self.id = try Star.query(on: database)
                        .filter(\.$name == name)
                        .first().wait()!
                        .requireID()
                    self.name = name
                }
            }

            let sun = try StarJSON(name: "Milky Way", on: self.database)
            let alphaCentauri = try StarJSON(name: "Alpha Centauri", on: self.database)
            let expected: [PlanetJSON] = try [
                .init(name: "Earth", star: sun, on: self.database),
                .init(name: "Jupiter", star: sun, on: self.database),
                .init(name: "Mars", star: sun, on: self.database),
                .init(name: "Mercury", star: sun, on: self.database),
                .init(name: "Neptune", star: sun, on: self.database),
                .init(name: "Proxima Centauri b", star: alphaCentauri, on: self.database),
                .init(name: "Saturn", star: sun, on: self.database),
                .init(name: "Uranus", star: sun, on: self.database),
                .init(name: "Venus", star: sun, on: self.database),
            ]

            let planets = try Planet.query(on: self.database)
                .with(\.$star)
                .sort(\.$name)
                .all().wait()

            let decoded = try JSONDecoder().decode(
                [PlanetJSON].self,
                from: JSONEncoder().encode(planets)
            )
            XCTAssertEqual(decoded, expected)
        }
    }

    public func testEagerLoadChildrenJSON() throws {
        try self.runTest(#function, [
            SolarSystem()
        ]) {
            struct StarJSON: Codable, Equatable {
                static func ==(lhs: Self, rhs: Self) -> Bool {
                    lhs.name == rhs.name && lhs.galaxy == rhs.galaxy
                }

                struct GalaxyID: Codable, Equatable {
                    static func ==(lhs: Self, rhs: Self) -> Bool {
                        true
                    }

                    var id: UUID = .init()
                }

                var id: UUID = .init()
                var name: String
                var galaxy: GalaxyID = .init()
            }

            struct GalaxyJSON: Codable, Equatable {
                static func ==(lhs: Self, rhs: Self) -> Bool {
                    lhs.name == rhs.name && lhs.stars == lhs.stars
                }

                var id: UUID = .init()
                var name: String
                var stars: [StarJSON]
            }

            let expected: [GalaxyJSON] = [
                .init(name: "Andromeda", stars: [
                    .init(name: "Alpheratz"),
                ]),
                .init(name: "Messier 82", stars: []),
                .init(name: "Milky Way", stars: [
                    .init(name: "Alpha Centauri"),
                    .init(name: "Sun"),
                ]),
                .init(name: "Pinwheel", stars: [])
            ]

            var galaxies = try Galaxy.query(on: self.database)
                .with(\.$stars)
                .all().wait()

            // sort galaxies
            galaxies.sort {
                $0.name < $1.name
            }
            // sort stars in galaxies
            galaxies.forEach {
                $0.$stars.value?.sort {
                    $0.name < $1.name
                }
            }

            let decoded = try JSONDecoder().decode(
                [GalaxyJSON].self,
                from: JSONEncoder().encode(galaxies)
            )
            XCTAssertEqual(decoded, expected)
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
                    XCTAssertEqual(planet.tags.map { $0.name }, ["Small Rocky", "Inhabited"])
                case "Proxima Centauri b":
                    XCTAssertEqual(planet.star.name, "Alpha Centauri")
                    XCTAssertEqual(planet.tags.map { $0.name }, [])
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
