import FluentKit

public final class Moon: Model {
    public static let schema = "moons"

    @ID(key: "id")
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
        comets: Int,
        planetID: Planet.IDValue
    ) {
        self.id = id
        self.name = name
        self.craters = craters
        self.comets = comets
        self.$planet.id = planetID
    }
}

public struct MoonMigration: Migration {
    public init() { }

    public func prepare(on database: Database) -> EventLoopFuture<Void> {
        return database.schema("moons")
            .field("id", .uuid, .identifier(auto: false))
            .field("name", .string, .required)
            .field("craters", .int, .required)
            .field("comets", .int, .required)
            .field("planet_id", .int, .required, .references("planets", "id"))
            .create()
    }

    public func revert(on database: Database) -> EventLoopFuture<Void> {
        return database.schema("moons").delete()
    }
}

public final class MoonSeed: Migration {
    public init() { }

    public func prepare(on database: Database) -> EventLoopFuture<Void> {
        let saves = [
            Moon(name: "Deimos", craters: 1, comets: 5, planetID: 1),
            Moon(name: "Prometheus", craters: 8, comets: 19, planetID: 2),
            Moon(name: "Hydra", craters: 2, comets: 2, planetID: 3),
            Moon(name: "Luna", craters: 10, comets: 10, planetID: 4),
            Moon(name: "Atlas", craters: 9, comets: 8, planetID: 5),
            Moon(name: "Janus", craters: 15, comets: 9, planetID: 6),
            Moon(name: "Phobos", craters: 20, comets: 3, planetID: 7)
        ].map { moon -> EventLoopFuture<Void> in
            return moon.save(on: database)
        }
        return .andAllSucceed(saves, on: database.eventLoop)
    }

    public func revert(on database: Database) -> EventLoopFuture<Void> {
        return database.eventLoop.makeSucceededFuture(())
    }
}
