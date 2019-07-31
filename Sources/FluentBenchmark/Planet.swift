import FluentKit

final class Planet: Model {
    @Field var id: Int?
    @Field var name: String
    @Parent var galaxy: Galaxy

    init() { }

    init(id: Int? = nil, name: String, galaxyID: Galaxy.ID) {
        self.id = id
        self.name = name
        self.$galaxy.id = galaxyID
    }
}

struct PlanetMigration: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        return Planet.schema(on: database)
            .field(\.$id, .int, .identifier(auto: true))
            .field(\.$name, .string, .required)
            .field("galaxy_id", .int, .required)
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        return Planet.schema(on: database).delete()
    }
}

