import FluentKit

final class Planet: Model {
    static let schema = "planets"

    @ID(key: "id")
    var id: Int?

    @Field(key: "name")
    var name: String

    @Parent(key: "galaxy_id")
    var galaxy: Galaxy

    @Siblings(through: PlanetTag.self, from: \.$planet, to: \.$tag)
    var tags: [Tag]

    init() { }

    init(id: Int? = nil, name: String, galaxyID: Galaxy.IDValue) {
        self.id = id
        self.name = name
        self.$galaxy.id = galaxyID
    }
}

struct PlanetMigration: GenericMigration {
    typealias MigrationModel = Planet
    
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        return schema(for: database)
            .field("id", .int, .identifier(auto: true))
            .field("name", .string, .required)
            .field("galaxy_id", .int, .required)
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        return schema(for: database).delete()
    }
}

