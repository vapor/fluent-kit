final class Team: Model {
    static let schema = "teams"

    @ID(key: "id")
    var id: Int?

    @Field(key: "name")
    var name: String

    @Children(for: \.$homeTeam)
    var homeMatches: [Match]

    @Children(for: \.$awayTeam)
    var awayMatches: [Match]

    init() { }

    init(id: Int? = nil, name: String) {
        self.id = id
        self.name = name
    }
}

struct TeamMigration: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        return database.schema("teams")
            .field("id", .int, .identifier(auto: true))
            .field("name", .string, .required)
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        return database.schema("teams").delete()
    }
}
