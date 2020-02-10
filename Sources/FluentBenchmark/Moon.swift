import FluentKit

public final class Moon: Model {
    public static let schema = "moons"

    @ID(key: "id")
    public var id: Int?

    @Field(key: "name")
    public var name: String

    @Field(key: "craters")
    public var craters: Int

    @Field(key: "comets")
    public var comets: Int

    @Parent(key: "planet_id")
    public var planet: Planet

    public init() { }

    public init(id: Int? = nil, name: String, craters: Int, comets: Int, planetID: Planet.IDValue) {
        self.id = id
        self.name = name
        self.craters = craters
        self.comets = comets
        self.$planet.id = planetID
    }
}

public struct MoonMigration: Migration {
    public func prepare(on database: Database) -> EventLoopFuture<Void> {
        return database.schema("moons")
            .field("id", .int, .identifier(auto: true))
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

