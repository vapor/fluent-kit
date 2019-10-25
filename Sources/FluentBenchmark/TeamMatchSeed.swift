struct TeamMatchSeed: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        let a = Team(name: "a")
        let b = Team(name: "b")
        let c = Team(name: "c")
        return a.create(on: database).and(b.create(on: database)).and(c.create(on: database)).flatMap { _ -> EventLoopFuture<Void> in
            return .andAllSucceed([
                Match(name: "a vs. b", homeTeam: a, awayTeam: b).save(on: database),
                Match(name: "a vs. c", homeTeam: a, awayTeam: c).save(on: database),
                Match(name: "b vs. c", homeTeam: b, awayTeam: c).save(on: database),
                Match(name: "b vs. a", homeTeam: b, awayTeam: a).save(on: database),
                Match(name: "c vs. b", homeTeam: c, awayTeam: b).save(on: database),
                Match(name: "c vs. a", homeTeam: c, awayTeam: a).save(on: database),
            ], on: database.eventLoop)
        }

    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        return Match.query(on: database).delete().flatMap {
            return Team.query(on: database).delete()
        }

    }
}
