import FluentKit
import Foundation
import NIOCore

public final class Moon: Model {
    public static let schema = "moons"

    @ID(key: .id)
    public var id: UUID?

    @Field(key: "name")
    public var name: String

    @Field(key: "craters")
    public var craters: Int

    @Field(key: "comets")
    public var comets: Int

    @Parent(key: "planet_id")
    public var planet: Planet

    public init() { }

    public init(
        id: IDValue? = nil,
        name: String,
        craters: Int,
        comets: Int
    ) {
        self.id = id
        self.name = name
        self.craters = craters
        self.comets = comets
    }
}

public struct MoonMigration: Migration {
    public init() { }

    public func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema("moons")
            .field("id", .uuid, .identifier(auto: false))
            .field("name", .string, .required)
            .field("craters", .int, .required)
            .field("comets", .int, .required)
            .field("planet_id", .uuid, .required, .references("planets", "id"))
            .create()
    }

    public func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema("moons").delete()
    }
}

public final class MoonSeed: Migration {
    public init() { }

    public func prepare(on database: Database) -> EventLoopFuture<Void> {
        Planet.query(on: database).all().flatMap { planets in
            .andAllSucceed(planets.map { planet in
                let moons: [Moon]
                switch planet.name {
                case "Earth":
                    moons = [
                        .init(name: "Moon", craters: 10, comets: 10)
                    ]
                case "Mars":
                    moons = [
                        .init(name: "Deimos", craters: 1, comets: 5),
                        .init(name: "Phobos", craters: 20, comets: 3)
                    ]
                case "Jupiter":
                    moons = [
                        .init(name: "Io", craters: 10, comets: 10),
                        .init(name: "Europa", craters: 10, comets: 10),
                        .init(name: "Ganymede", craters: 10, comets: 10),
                        .init(name: "callisto", craters: 10, comets: 10),
                    ]
                case "Saturn":
                    moons = [
                        .init(name: "Titan", craters: 10, comets: 10),
                        .init(name: "Prometheus", craters: 10, comets: 10),
                        .init(name: "Atlas", craters: 9, comets: 8),
                        .init(name: "Janus", craters: 15, comets: 9)
                    ]
                default:
                    moons = []
                }
                return planet.$moons.create(moons, on: database)
            }, on: database.eventLoop)
        }
    }

    public func revert(on database: Database) -> EventLoopFuture<Void> {
        Moon.query(on: database).delete()
    }
}
