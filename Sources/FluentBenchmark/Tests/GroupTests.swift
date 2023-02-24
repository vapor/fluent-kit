import FluentKit
import Foundation
import NIOCore
import XCTest

extension FluentBenchmarker {
    public func testGroup() throws {
        try self.testGroup_flat()
//        try self.testGroup_nested()
    }
    func testGroup_flat() throws {
        try runTest(#function, [
            FlatMoonMigration(),
            FlatMoonSeed()
        ]) {
            // Test filtering moons
            let moons = try FlatMoon.query(on: self.database)
                .filter(\.$planet.$type == .smallRocky)
                .all().wait()

            XCTAssertEqual(moons.count, 1)
            guard let moon = moons.first else {
                return
            }

            XCTAssertEqual(moon.name, "Moon")
            XCTAssertEqual(moon.planet.name, "Earth")
            XCTAssertEqual(moon.planet.type, .smallRocky)
            XCTAssertEqual(moon.planet.star.name, "Sun")
            XCTAssertEqual(moon.planet.star.galaxy.name, "Milky Way")

            // Test JSON
            let json = prettyJSON(moon)
            self.database.logger.debug(json)
            let decoded = try JSONDecoder().decode(FlatMoon.self, from: Data(json.description.utf8))
            XCTAssertEqual(decoded.name, "Moon")
            XCTAssertEqual(decoded.planet.name, "Earth")
            XCTAssertEqual(decoded.planet.type, .smallRocky)
            XCTAssertEqual(decoded.planet.star.name, "Sun")
            XCTAssertEqual(decoded.planet.star.galaxy.name, "Milky Way")

            // Test deeper filter
            let all = try FlatMoon.query(on: self.database)
                .filter(\.$planet.$star.$galaxy.$name == "Milky Way")
                .all()
                .wait()
            XCTAssertEqual(all.count, 2)
        }
    }

//    func testGroup_nested() throws {
//        try runTest(#function, [
//            NestedMoonMigration(),
//            NestedMoonSeed()
//        ]) {
//            // Test filtering moons
//            let moons = try NestedMoon.query(on: self.database)
//                .filter(\.$planet.$type == .smallRocky)
//                .all().wait()
//
//            XCTAssertEqual(moons.count, 1)
//            guard let moon = moons.first else {
//                return
//            }
//
//            XCTAssertEqual(moon.name, "Moon")
//            XCTAssertEqual(moon.planet.name, "Earth")
//            XCTAssertEqual(moon.planet.type, .smallRocky)
//            XCTAssertEqual(moon.planet.star.name, "Sun")
//            XCTAssertEqual(moon.planet.star.galaxy.name, "Milky Way")
//
//            // Test JSON
//            let json = try prettyJSON(moon)
//            let decoded = try JSONDecoder().decode(NestedMoon.self, from: Data(json.utf8))
//            XCTAssertEqual(decoded.name, "Moon")
//            XCTAssertEqual(decoded.planet.name, "Earth")
//            XCTAssertEqual(decoded.planet.type, .smallRocky)
//            XCTAssertEqual(decoded.planet.star.name, "Sun")
//            XCTAssertEqual(decoded.planet.star.galaxy.name, "Milky Way")
//
//            // Test deeper filter
//            let all = try FlatMoon.query(on: self.database)
//                .filter(\.$planet.$star.$galaxy.$name == "Milky Way")
//                .all()
//                .wait()
//            XCTAssertEqual(all.count, 2)
//        }
//    }
}

// MARK: Flat

private final class FlatMoon: Model {
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

            @Group(key: "galaxy")
            var galaxy: Galaxy

            init() { }

            init(name: String, galaxy: Galaxy) {
                self.name = name
                self.galaxy = galaxy
            }
        }

        @Group(key: "star")
        var star: Star

        init() { }

        init(name: String, type: PlanetType, star: Star) {
            self.name = name
            self.type = type
            self.star = star
        }
    }

    @Group(key: "planet")
    var planet: Planet

    init() { }

    init(id: IDValue? = nil, name: String, planet: Planet) {
        self.id = id
        self.name = name
        self.planet = planet
    }
}


private struct FlatMoonMigration: Migration {
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


private struct FlatMoonSeed: Migration {
    init() { }

    func prepare(on database: Database) -> EventLoopFuture<Void> {
        let moon = FlatMoon(
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
        let europa = FlatMoon(
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

// MARK: Nested

//private final class NestedMoon: Model {
//    static let schema = "moons"
//
//    @ID(key: .id)
//    var id: UUID?
//
//    @Field(key: "name")
//    var name: String
//
//    final class Planet: Fields {
//        @Field(key: "name")
//        var name: String
//
//        enum PlanetType: String, Codable {
//            case smallRocky, gasGiant, dwarf
//        }
//
//        @Field(key: "type")
//        var type: PlanetType
//
//        final class Star: Fields {
//            @Field(key: "name")
//            var name: String
//
//            final class Galaxy: Fields {
//                @Field(key: "name")
//                var name: String
//
//                init() { }
//
//                init(name: String) {
//                    self.name = name
//                }
//            }
//
//            @Group(key: "galaxy", structure: .nested)
//            var galaxy: Galaxy
//
//            init() { }
//
//            init(name: String, galaxy: Galaxy) {
//                self.name = name
//                self.galaxy = galaxy
//            }
//        }
//
//        @Group(key: "star", structure: .nested)
//        var star: Star
//
//        init() { }
//
//        init(name: String, type: PlanetType, star: Star) {
//            self.name = name
//            self.type = type
//            self.star = star
//        }
//    }
//
//    @Group(key: "planet", structure: .nested)
//    var planet: Planet
//
//    init() { }
//
//    init(id: IDValue? = nil, name: String, planet: Planet) {
//        self.id = id
//        self.name = name
//        self.planet = planet
//    }
//}
//
//
//private struct NestedMoonMigration: Migration {
//    func prepare(on database: Database) -> EventLoopFuture<Void> {
//        database.schema("moons")
//            .field("id", .uuid, .identifier(auto: false))
//            .field("name", .string, .required)
//            .field("planet", .json, .required)
//            .create()
//    }
//
//    func revert(on database: Database) -> EventLoopFuture<Void> {
//        database.schema("moons").delete()
//    }
//}
//
//
//private struct NestedMoonSeed: Migration {
//    init() { }
//
//    func prepare(on database: Database) -> EventLoopFuture<Void> {
//        let moon = NestedMoon(
//            name: "Moon",
//            planet: .init(
//                name: "Earth",
//                type: .smallRocky,
//                star: .init(
//                    name: "Sun",
//                    galaxy: .init(name: "Milky Way")
//                )
//            )
//        )
//        let europa = NestedMoon(
//            name: "Moon",
//            planet: .init(
//                name: "Jupiter",
//                type: .gasGiant,
//                star: .init(
//                    name: "Sun",
//                    galaxy: .init(name: "Milky Way")
//                )
//            )
//        )
//        return moon.save(on: database)
//            .and(europa.save(on: database))
//            .map { _ in }
//    }
//
//    func revert(on database: Database) -> EventLoopFuture<Void> {
//        database.eventLoop.makeSucceededFuture(())
//    }
//}
//
