import FluentKit

final class Galaxy: Model {
    @ID("id") var id: Int?
    @Field("name") var name: String
    @Children(\.$galaxy) var planets: [Planet]

    init() { }

    init(id: Int? = nil, name: String) {
        self.id = id
        self.name = name
    }
}

struct GalaxyMigration: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        return Galaxy.schema(on: database)
            .field("id", .int, .identifier(auto: true))
            .field("name", .string, .required)
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        return Galaxy.schema(on: database).delete()
    }
}
