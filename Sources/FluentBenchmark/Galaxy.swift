import FluentKit

final class Galaxy: Model {
    static let schema = "galaxies"
    
    @ID(key: "id")
    var id: Int?

    @Field(key: "name")
    var name: String

    @Children(from: \.$galaxy)
    var planets: [Planet]

    init() { }

    init(id: Int? = nil, name: String) {
        self.id = id
        self.name = name
    }
}

struct GalaxyMigration: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        return database.schema("galaxies")
            .field("id", .int, .identifier(auto: true))
            .field("name", .string, .required)
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        return database.schema("galaxies").delete()
    }
}
