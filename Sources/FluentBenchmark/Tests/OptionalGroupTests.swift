extension FluentBenchmarker {
    public func testOptionalGroup() throws {
        try runTest(#function, [
            OptionalGroupMoonMigration(),
            OptionalGroupMoonSeed()
        ]) {
            // Test filtering moons
            let moons = try OptionalGroupMoon.query(on: self.database)
                .filter(\.$planet.$type == .smallRocky)
                .all().wait()

            XCTAssertEqual(moons.count, 1)
            guard let moon = moons.first else {
                return
            }
            print(moon)

            // Test with planet
            XCTAssertEqual(moon.name, "Moon")
            XCTAssertEqual(moon.planet?.name, "Earth")
            XCTAssertEqual(moon.planet?.type, .smallRocky)
            XCTAssertEqual(moon.planet?.star?.name, "Sun")
            XCTAssertEqual(moon.planet?.star?.galaxy.name, "Milky Way")

            // Test JSON with planet
            let json = try prettyJSON(moon)
            print(json)
            let decoded = try JSONDecoder().decode(OptionalGroupMoon.self, from: Data(json.utf8))
            print(decoded)
            XCTAssertEqual(decoded.name, "Moon")
            XCTAssertEqual(decoded.planet?.name, "Earth")
            XCTAssertEqual(decoded.planet?.type, .smallRocky)
            XCTAssertEqual(decoded.planet?.star?.name, "Sun")
            XCTAssertEqual(decoded.planet?.star?.galaxy.name, "Milky Way")


            // Test deeper filter
            let all = try OptionalGroupMoon.query(on: self.database)
                .filter(\.$planet.$star.$galaxy.$name == "Milky Way")
                .all()
                .wait()
            XCTAssertEqual(all.count, 2)

            // Test without star
            guard let moonWithoutStar = try OptionalGroupMoon.query(on: self.database)
                .filter(\.$planet.$exists == true)
                .filter(\.$planet.$star.$exists == false)
                .first()
                .wait() else {
                XCTFail("Failed to get optional_moon without star")
                return
            }

            print(moonWithoutStar)
            XCTAssertEqual(moonWithoutStar.name, "Moon")
            XCTAssertEqual(moonWithoutStar.planet?.name, "OTS 44")
            XCTAssertEqual(moonWithoutStar.planet?.type, .gasGiant)
            XCTAssertNil(moonWithoutStar.planet?.star)

            // Test without planet
            guard let moonsWithouPlanet = try OptionalGroupMoon.query(on: self.database)
                .filter(\.$planet.$exists == false)
                .first()
                .wait() else {
                XCTFail("Failed to get optional_moon without planet")
                return
            }

            print(moonsWithouPlanet)
            XCTAssertEqual(moonsWithouPlanet.name, "Moon")
            XCTAssertNil(moonsWithouPlanet.planet)
        }
    }
}

private final class OptionalGroupMoon: Model {
    static let schema = "optional_moons"

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

            @Group(key: "galaxy")
            var galaxy: Galaxy

            init() { }

            init(name: String, galaxy: Galaxy) {
                self.name = name
                self.galaxy = galaxy
            }
        }

        @OptionalGroup(key: "star")
        var star: Star?

        init() { }

        init(name: String, type: PlanetType, star: Star?) {
            self.name = name
            self.type = type
            self.star = star
        }
    }

    @OptionalGroup(key: "planet")
    var planet: Planet?

    init() { }

    init(id: IDValue? = nil, name: String, planet: Planet?) {
        self.id = id
        self.name = name
        self.planet = planet
    }
}


private struct OptionalGroupMoonMigration: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema("optional_moons")
            .field("id", .uuid, .identifier(auto: false))
            .field("name", .string, .required)
            .field("planet_exists", .bool)
            .field("planet_name", .string)
            .field("planet_type", .string)
            .field("planet_star_exists", .bool)
            .field("planet_star_name", .string)
            .field("planet_star_galaxy_name", .string)
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema("optional_moons").delete()
    }
}


private struct OptionalGroupMoonSeed: Migration {
    init() { }

    func prepare(on database: Database) -> EventLoopFuture<Void> {
        let moon = OptionalGroupMoon(
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
        let europa = OptionalGroupMoon(
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
        let roguePlanetMoon = OptionalGroupMoon(
            name: "Moon",
            planet: .init(
                name: "OTS 44",
                type: .gasGiant,
                star: nil
            )
        )
        let rogueMoon = OptionalGroupMoon(
            name: "Moon",
            planet: nil
        )
        return moon.save(on: database)
            .and(europa.save(on: database))
            .and(roguePlanetMoon.save(on: database))
            .and(rogueMoon.save(on: database))
            .map { _ in }
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.eventLoop.makeSucceededFuture(())
    }
}
