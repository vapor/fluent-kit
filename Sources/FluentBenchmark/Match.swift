final class Match: Model {
    static let schema = "matches"

    @ID(key: "id")
    var id: Int?

    @Field(key: "name")
    var name: String

    @Parent(key: "home_team_id")
    var homeTeam: Team

    @Parent(key: "away_team_id")
    var awayTeam: Team

    init() { }

    init(id: Int? = nil, name: String, homeTeam: Team, awayTeam: Team) {
        self.id = id
        self.name = name
        self.$homeTeam.id = homeTeam.id!
        self.$awayTeam.id = awayTeam.id!
    }
}

struct MatchMigration: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        return database.schema("matches")
            .field("id", .int, .identifier(auto: true))
            .field("name", .string, .required)
            .field("away_team_id", .int, .required)
            .field("home_team_id", .int, .required)
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        return database.schema("matches").delete()
    }
}
