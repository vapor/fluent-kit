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
        #warning("simplify field access")
        self.$planet.id = planetID
        self.$tag.id = tagID
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

struct PlanetTagSeed: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        // small rocky = 1, gas giant = 2, inhabited = 3
        // mercury = 1, venus = 2, earth = 3, mars = 4, jupiter = 5, saturn = 6, uranus = 7, neptune = 8
        return .andAllSucceed([
            // small rocky
            PlanetTag(planetID: 1, tagID: 1).save(on: database),
            PlanetTag(planetID: 2, tagID: 1).save(on: database),
            PlanetTag(planetID: 3, tagID: 1).save(on: database),
            PlanetTag(planetID: 4, tagID: 1).save(on: database),
            // gas giants
            PlanetTag(planetID: 5, tagID: 2).save(on: database),
            PlanetTag(planetID: 6, tagID: 2).save(on: database),
            PlanetTag(planetID: 7, tagID: 2).save(on: database),
            PlanetTag(planetID: 8, tagID: 2).save(on: database),
            // inhabited
            PlanetTag(planetID: 3, tagID: 3).save(on: database),
        ], on: database.eventLoop)
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        return PlanetTag.query(on: database).delete()
    }
}
