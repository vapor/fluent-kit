import FluentKit

final class PlanetTag: Model {
    static let schema = "planet+tag"
    
    @ID(key: "id")
    var id: Int?

    @Parent(key: "planet_id")
    var planet: Planet

    @Parent(key: "tag_id")
    var tag: Tag

    init() { }

    init(planetID: Int, tagID: Int) {
        self.planet.id = planetID
        self.tag.id = tagID
    }
}

struct PlanetTagMigration: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        return database.schema("planet+tag")
            .field("id", .int, .identifier(auto: true))
            .field("planet_id", .int, .required)
            .field("tag_id", .int, .required)
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        return database.schema("planet+tag").delete()
    }
}
