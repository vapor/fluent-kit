import FluentKit

final class MoonSeed: Migration {
    init() { }

    func prepare(on database: Database) -> EventLoopFuture<Void> {
        let saves = [
            Moon(name: "Deimos", craters: 1, comets: 5, planetID: 1),
            Moon(name: "Prometheus", craters: 8, comets: 19, planetID: 2),
            Moon(name: "Hydra", craters: 2, comets: 2, planetID: 3),
            Moon(name: "Luna", craters: 10, comets: 10, planetID: 4),
            Moon(name: "Atlas", craters: 9, comets: 8, planetID: 5),
            Moon(name: "Janus", craters: 15, comets: 9, planetID: 6),
            Moon(name: "Phobos", craters: 20, comets: 3, planetID: 7)
        ].map { moon -> EventLoopFuture<Void> in
            return moon.save(on: database)
        }
        return .andAllSucceed(saves, on: database.eventLoop)
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        return database.eventLoop.makeSucceededFuture(())
    }
}
