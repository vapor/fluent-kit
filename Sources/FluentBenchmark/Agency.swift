import FluentKit

final class Agency: Model {
    static let schema: String = "agencies"
    static var qutheory: Agency { Agency(name: "Qutheory, LLC") }

    @ID(key: "id")
    var id: Int?

    @Field(key: "name")
    var name: String

    @Children(from: \.$agency)
    var users: [User]

    init() { }

    init(id: Int? = nil, name: String) {
        self.id = id
        self.name = name
    }
}

struct AgencyMigration: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        return database.schema(Agency.schema)
            .field("id", .int, .identifier(auto: true))
            .field("name", .string, .required)
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        return database.schema(Agency.schema).delete()
    }
}

final class AgencySeed: Migration {
    init() { }

    func prepare(on database: Database) -> EventLoopFuture<Void> {
        return Agency.qutheory.save(on: database)
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        return Agency.query(on: database).delete()
    }
}
