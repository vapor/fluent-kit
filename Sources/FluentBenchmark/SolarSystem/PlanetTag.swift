import FluentKit

public final class PlanetTag: Model {
    public static let schema = "planet+tag"
    
    @ID(key: "id")
    public var id: UUID?

    @Parent(key: "planet_id")
    public var planet: Planet

    @Parent(key: "tag_id")
    public var tag: Tag

    public init() { }

    public init(id: IDValue? = nil, planetID: Planet.IDValue, tagID: Tag.IDValue) {
        self.id = id
        self.$planet.id = planetID
        self.$tag.id = tagID
    }
}

public struct PlanetTagMigration: Migration {
    public init() { }

    public func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema("planet+tag")
            .field("id", .uuid, .identifier(auto: false))
            .field("planet_id", .uuid, .required, .references("planets", "id"))
            .field("tag_id", .uuid, .required, .references("tags", "id"))
            .create()
    }

    public func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema("planet+tag").delete()
    }
}

public struct PlanetTagSeed: Migration {
    public init() { }
    
    public func prepare(on database: Database) -> EventLoopFuture<Void> {
        let planets = Planet.query(on: database).all()
        let tags = Tag.query(on: database).all()
        return planets.and(tags).flatMap { (planets, tags) in
            let inhabited = tags.filter { $0.name == "Inhabited" }.first!
            let gasGiant = tags.filter { $0.name == "Gas Giant" }.first!
            let smallRocky = tags.filter { $0.name == "Small Rocky" }.first!

            return .andAllSucceed(planets.map { planet in
                let tags: [Tag]
                switch planet.name {
                case "Mercury", "Venus", "Mars", "Proxima Centauri b":
                    tags = [smallRocky]
                case "Earth":
                    tags = [inhabited, smallRocky]
                case "Jupiter", "Saturn", "Uranus", "Neptune":
                    tags = [gasGiant]
                default:
                    tags = []
                }
                return planet.$tags.attach(tags, on: database)
            }, on: database.eventLoop)
        }
    }

    public func revert(on database: Database) -> EventLoopFuture<Void> {
        PlanetTag.query(on: database).delete()
    }
}
