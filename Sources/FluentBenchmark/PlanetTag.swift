import FluentKit

final class PlanetTag: Model {
    @ID("id") var id: Int?
    @Field("planet_id") var planetID: Int
    @Field("tag_id") var tagID: Int

    init() { }

    init(planetID: Int, tagID: Int) {
        self.planetID = planetID
        self.tagID = tagID
    }
}

extension PlanetTag: Pivot {
    typealias Left = Planet
    var leftID: Field<Int> {
        return self.$planetID
    }
    typealias Right = Tag
    var rightID: Field<Int> {
        return self.$tagID
    }
}

struct PlanetTagMigration: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        return PlanetTag.schema(on: database)
            .field("id", .int, .identifier(auto: true))
            .field("planet_id", .int, .required)
            .field("tag_id", .int, .required)
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        return PlanetTag.schema(on: database).delete()
    }
}
