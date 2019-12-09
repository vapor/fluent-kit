import FluentKit

final class GalaxySeed: Migration {
    init() { }
    
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        let saves = [
            "Andromeda",
            "Milky Way",
            "Messier 82"
        ].map {
            Galaxy(name: $0)
                .save(on: database)
        }
        return .andAllSucceed(saves, on: database.eventLoop)
    }
    
    func revert(on database: Database) -> EventLoopFuture<Void> {
        return database.eventLoop.makeSucceededFuture(())
    }
}
