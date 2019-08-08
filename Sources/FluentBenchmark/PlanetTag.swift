import FluentKit

final class PlanetTag: Pivot {
    typealias Left = Planet
    static var leftID: PartialKeyPath<PlanetTag> {
        return \.$planetID
    }

    typealias Right = Tag
    static var rightID: PartialKeyPath<PlanetTag> {
        return \.$tagID
    }


    @Field var id: Int?
    @Field var planetID: Int
    @Field var tagID: Int

    init() { }

    init(planetID: Int, tagID: Int) {
        self.planetID = planetID
        self.tagID = tagID
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
