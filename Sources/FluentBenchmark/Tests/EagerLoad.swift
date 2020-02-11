extension FluentBenchmarker {
    public func testEagerLoading() throws {
        try runTest(#function, [
            GalaxyMigration(),
            PlanetMigration(),
            MoonMigration(),
            GalaxySeed(),
            PlanetSeed(),
            MoonSeed()
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
        try runTest(#function, [
            GalaxyMigration(),
            PlanetMigration(),
            GalaxySeed(),
            PlanetSeed()
        ]) {
            let galaxies = try Galaxy.query(on: self.database)
                .with(\.$planets)
                .all().wait()

            for galaxy in galaxies {
                switch galaxy.name {
                case "Milky Way":
                    guard galaxy.planets.contains(where: { $0.name == "Earth" }) else {
                        throw Failure("unexpected missing planet")
                    }
                    guard !galaxy.planets.contains(where: { $0.name == "PA-99-N2"}) else {
                        throw Failure("unexpected planet")
                    }
                default: break
                }
            }
        }
    }

    public func testEagerLoadParent() throws {
        try runTest(#function, [
            GalaxyMigration(),
            PlanetMigration(),
            GalaxySeed(),
            PlanetSeed()
        ]) {
            let planets = try Planet.query(on: self.database)
                .with(\.$galaxy)
                .all().wait()

            for planet in planets {
                switch planet.name {
                case "Earth":
                    guard planet.galaxy.name == "Milky Way" else {
                        throw Failure("unexpected galaxy name: \(planet.galaxy)")
                    }
                case "PA-99-N2":
                    guard planet.galaxy.name == "Andromeda" else {
                        throw Failure("unexpected galaxy name: \(planet.galaxy)")
                    }
                default: break
                }
            }
        }
    }

    public func testEagerLoadParentJoin() throws {
        try runTest(#function, [
            GalaxyMigration(),
            PlanetMigration(),
            GalaxySeed(),
            PlanetSeed()
        ]) {
            let planets = try Planet.query(on: self.database)
                .with(\.$galaxy)
                .all().wait()

            for planet in planets {
                switch planet.name {
                case "Earth":
                    guard planet.galaxy.name == "Milky Way" else {
                        throw Failure("unexpected galaxy name: \(planet.galaxy)")
                    }
                case "PA-99-N2":
                    guard planet.galaxy.name == "Andromeda" else {
                        throw Failure("unexpected galaxy name: \(planet.galaxy)")
                    }
                default: break
                }
            }
        }
    }

    public func testEagerLoadParentJSON() throws {
        try runTest(#function, [
            GalaxyMigration(),
            PlanetMigration(),
            GalaxySeed(),
            PlanetSeed()
        ]) {
            struct PlanetJSON: Codable, Equatable {
                var id: Int
                var name: String
                var galaxy: GalaxyJSON

                init(name: String, galaxy: GalaxyJSON, on database: Database) throws {
                    self.id = try Planet.query(on: database)
                        .filter(\.$name == name)
                        .first().wait()?
                        .id ?? 0
                    self.name = name
                    self.galaxy = galaxy
                }
            }
            struct GalaxyJSON: Codable, Equatable {
                var id: Int
                var name: String

                init(name: String, on database: Database) throws {
                    self.id = try Galaxy.query(on: database)
                        .filter(\.$name == name)
                        .first().wait()?
                        .id ?? 0
                    self.name = name
                }
            }

            let milkyWay = try GalaxyJSON(name: "Milky Way", on: self.database)
            let andromeda = try GalaxyJSON(name: "Andromeda", on: self.database)
            let expected: [PlanetJSON] = try [
                .init(name: "Mercury", galaxy: milkyWay, on: self.database),
                .init(name: "Venus", galaxy: milkyWay, on: self.database),
                .init(name: "Earth", galaxy: milkyWay, on: self.database),
                .init(name: "Mars", galaxy: milkyWay, on: self.database),
                .init(name: "Jupiter", galaxy: milkyWay, on: self.database),
                .init(name: "Saturn", galaxy: milkyWay, on: self.database),
                .init(name: "Uranus", galaxy: milkyWay, on: self.database),
                .init(name: "Neptune", galaxy: milkyWay, on: self.database),
                .init(name: "PA-99-N2", galaxy: andromeda, on: self.database),
            ]

            // subquery
            do {
                let planets = try Planet.query(on: self.database)
                    .with(\.$galaxy)
                    .all().wait()

                let decoded = try JSONDecoder().decode([PlanetJSON].self, from: JSONEncoder().encode(planets))
                XCTAssertEqual(decoded, expected)
            }

            // join
            do {
                let planets = try Planet.query(on: self.database)
                    .with(\.$galaxy)
                    .all().wait()

                let decoded = try JSONDecoder().decode([PlanetJSON].self, from: JSONEncoder().encode(planets))
                XCTAssertEqual(decoded, expected)
            }
        }
    }

    public func testEagerLoadChildrenJSON() throws {
        try runTest(#function, [
            GalaxyMigration(),
            PlanetMigration(),
            GalaxySeed(),
            PlanetSeed()
        ]) {
            struct PlanetJSON: Codable, Equatable {
                struct GalaxyID: Codable, Equatable {
                    var id: Int
                }
                var id: Int
                var name: String
                var galaxy: GalaxyID
            }
            struct GalaxyJSON: Codable, Equatable {
                var id: Int
                var name: String
                var planets: [PlanetJSON]
            }

            let andromeda = GalaxyJSON(id: 1, name: "Andromeda", planets: [
                .init(id: 9, name: "PA-99-N2", galaxy: .init(id: 1)),
            ])
            let milkyWay = GalaxyJSON(id: 2, name: "Milky Way", planets: [
                .init(id: 1, name: "Mercury", galaxy: .init(id: 2)),
                .init(id: 2, name: "Venus", galaxy: .init(id: 2)),
                .init(id: 3, name: "Earth", galaxy: .init(id: 2)),
                .init(id: 4, name: "Mars", galaxy: .init(id: 2)),
                .init(id: 5, name: "Jupiter", galaxy: .init(id: 2)),
                .init(id: 6, name: "Saturn", galaxy: .init(id: 2)),
                .init(id: 7, name: "Uranus", galaxy: .init(id: 2)),
                .init(id: 8, name: "Neptune", galaxy: .init(id: 2)),
            ])
            let messier82 = GalaxyJSON(id: 3, name: "Messier 82", planets: [])
            let expected: [GalaxyJSON] = [andromeda, milkyWay, messier82]

            let galaxies = try Galaxy.query(on: self.database)
                .with(\.$planets)
                .all().wait()

            let decoded = try JSONDecoder().decode([GalaxyJSON].self, from: JSONEncoder().encode(galaxies))
            guard decoded == expected else {
                throw Failure("unexpected output")
            }
        }
    }

    public func testSiblingsEagerLoad() throws {
        // seeded db
        try runTest(#function, [
            GalaxyMigration(),
            GalaxySeed(),
            PlanetMigration(),
            PlanetSeed(),
            TagMigration(),
            TagSeed(),
            PlanetTagMigration(),
            PlanetTagSeed()
        ]) {
            let planets = try Planet.query(on: self.database)
                .with(\.$galaxy)
                .with(\.$tags)
                .all().wait()

            for planet in planets {
                switch planet.name {
                case "Earth":
                    XCTAssertEqual(planet.galaxy.name, "Milky Way")
                    XCTAssertEqual(planet.tags.map { $0.name }, ["Small Rocky", "Inhabited"])
                case "PA-99-N2":
                    XCTAssertEqual(planet.galaxy.name, "Andromeda")
                    XCTAssertEqual(planet.tags.map { $0.name }, [])
                case "Jupiter":
                    XCTAssertEqual(planet.galaxy.name, "Milky Way")
                    XCTAssertEqual(planet.tags.map { $0.name }, ["Gas Giant"])
                default: break
                }
            }
        }
    }

    // https://github.com/vapor/fluent-kit/issues/117
    public func testEmptyEagerLoadChildren() throws {
        try runTest(#function, [
            GalaxyMigration(),
            PlanetMigration(),
            GalaxySeed(),
            PlanetSeed()
        ]) {
            let galaxies = try Galaxy.query(on: self.database)
                .filter(\.$name == "foo")
                .with(\.$planets)
                .all().wait()

            XCTAssertEqual(galaxies.count, 0)
        }
    }
}
