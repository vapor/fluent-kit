import FluentKit

final class Planet: Model {
    @ID("id") var id: Int?
    @Field("name") var name: String
    @Parent("galaxy_id") var galaxy: Galaxy
    @Siblings(PlanetTag.self) var tags: [Tag]

    init() { }

    init(id: Int? = nil, name: String, galaxyID: Galaxy.IDValue) {
        self.id = id
        self.name = name
        self.$galaxy.id = galaxyID
    }
}

struct PlanetMigration: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        return Planet.schema(on: database)
            .field("id", .int, .identifier(auto: true))
            .field("name", .string, .required)
            .field("galaxy_id", .int, .required)
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        return Planet.schema(on: database).delete()
    }
}

