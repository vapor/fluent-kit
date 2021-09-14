import FluentKit

public final class Galaxy: Model {
    public static let schema = "galaxies"
    
    @ID(key: .id)
    public var id: UUID?

    @Field(key: "name")
    public var name: String
    
    @Group(key: "area")
    public var size: Size

    @Children(for: \.$galaxy)
    public var stars: [Star]

    public init() { }

    public init(id: UUID? = nil, name: String) {
        self.id = id
        self.name = name
    }
}

public final class Size: Fields {
    @Field(key: "km")
    var km: Double
    
    @Field(key: "light_year")
    var lightYear: Double
    
    public init() { }
}

public struct GalaxyMigration: Migration {
    public init() {}

    public func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema("galaxies")
            .field("id", .uuid, .identifier(auto: false))
            .field("name", .string, .required)
            .field("area_km", .double, .required, .sql(.default(0.0)))
            .field("area_light_year", .double, .required, .sql(.default(0.0)))
            .create()
    }

    public func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema("galaxies").delete()
    }
}

public struct GalaxySeed: Migration {
    public init() { }

    public func prepare(on database: Database) -> EventLoopFuture<Void> {
        .andAllSucceed([
            "Andromeda",
            "Milky Way",
            "Pinwheel Galaxy",
            "Messier 82"
        ].map {
            Galaxy(name: $0)
                .create(on: database)
        }, on: database.eventLoop)
    }

    public func revert(on database: Database) -> EventLoopFuture<Void> {
        Galaxy.query(on: database).delete()
    }
}
