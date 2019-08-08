import FluentKit

final class Tag: Model {
    @ID("id") var id: Int?
    @Field("name") var name: String
    @Siblings(PlanetTag.self) var planets: [Planet]

    init() { }

    init(id: Int? = nil, name: String) {
        self.id = id
        self.name = name
    }
}

struct TagMigration: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        return Tag.schema(on: database)
            .field("id", .int, .identifier(auto: true))
            .field("name", .string, .required)
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        return Tag.schema(on: database).delete()
    }
}
