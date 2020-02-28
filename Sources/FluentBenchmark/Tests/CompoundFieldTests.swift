extension FluentBenchmarker {
    public func testCompoundField() throws {
        try runTest(#function, [
            CompoundMoonMigration(),
            CompoundMoonSeed()
        ]) {
            // Test filtering moons
            let moons = try CompoundMoon.query(on: self.database)
                .filter(\.$planet.$type == .smallRocky)
                .all().wait()

            XCTAssertEqual(moons.count, 1)
            guard let moon = moons.first else {
                return
            }
            print(moon)

            XCTAssertEqual(moon.name, "Moon")
            XCTAssertEqual(moon.planet.name, "Earth")
            XCTAssertEqual(moon.planet.type, .smallRocky)
            XCTAssertEqual(moon.planet.star.name, "Sun")
            XCTAssertEqual(moon.planet.star.galaxy.name, "Milky Way")

            // Test JSON
            let json = try prettyJSON(moon)
            print(json)
            let decoded = try JSONDecoder().decode(CompoundMoon.self, from: Data(json.utf8))
            print(decoded)
            XCTAssertEqual(decoded.name, "Moon")
            XCTAssertEqual(decoded.planet.name, "Earth")
            XCTAssertEqual(decoded.planet.type, .smallRocky)
            XCTAssertEqual(decoded.planet.star.name, "Sun")
            XCTAssertEqual(decoded.planet.star.galaxy.name, "Milky Way")

            // Test deeper filter
            let all = try CompoundMoon.query(on: self.database)
                .filter(\.$planet.$star.$galaxy.$name == "Milky Way")
                .all()
                .wait()
            XCTAssertEqual(all.count, 2)
        }
    }
}

private final class CompoundMoon: Model {
    static let schema = "moons"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "name")
    var name: String

    final class Planet: Fields {
        @Field(key: "name")
        var name: String

        enum PlanetType: String, Codable {
            case smallRocky, gasGiant, dwarf
        }

        @Field(key: "type")
        var type: PlanetType

        final class Star: Fields {
            @Field(key: "name")
            var name: String

            final class Galaxy: Fields {
                @Field(key: "name")
                var name: String

                init() { }

                init(name: String) {
                    self.name = name
                }
            }

            @CompoundField(key: "galaxy")
            var galaxy: Galaxy

            init() { }

            init(name: String, galaxy: Galaxy) {
                self.name = name
                self.galaxy = galaxy
            }
        }

        @CompoundField(key: "star")
        var star: Star

        init() { }

        init(name: String, type: PlanetType, star: Star) {
            self.name = name
            self.type = type
            self.star = star
        }
    }

    @CompoundField(key: "planet")
    var planet: Planet

    init() { }

    init(id: IDValue? = nil, name: String, planet: Planet) {
        self.id = id
        self.name = name
        self.planet = planet
    }
}


private struct CompoundMoonMigration: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema("moons")
            .field("id", .uuid, .identifier(auto: false))
            .field("name", .string, .required)
            .field("planet_name", .string, .required)
            .field("planet_type", .string, .required)
            .field("planet_star_name", .string, .required)
            .field("planet_star_galaxy_name", .string, .required)
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema("moons").delete()
    }
}


private struct CompoundMoonSeed: Migration {
    init() { }

    func prepare(on database: Database) -> EventLoopFuture<Void> {
        let moon = CompoundMoon(
            name: "Moon",
            planet: .init(
                name: "Earth",
                type: .smallRocky,
                star: .init(
                    name: "Sun",
                    galaxy: .init(name: "Milky Way")
                )
            )
        )
        let europa = CompoundMoon(
            name: "Moon",
            planet: .init(
                name: "Jupiter",
                type: .gasGiant,
                star: .init(
                    name: "Sun",
                    galaxy: .init(name: "Milky Way")
                )
            )
        )
        return moon.save(on: database)
            .and(europa.save(on: database))
            .map { _ in }
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.eventLoop.makeSucceededFuture(())
    }
}
