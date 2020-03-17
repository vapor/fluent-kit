import AsyncKit

private let migrations: [Migration] = [
    GalaxyMigration(),
    StarMigration(),
    PlanetMigration(),
    MoonMigration(),
    TagMigration(),
    PlanetTagMigration(),
]

private let seeds: [Migration] = [
    GalaxySeed(),
    StarSeed(),
    PlanetSeed(),
    MoonSeed(),
    TagSeed(),
    PlanetTagSeed(),
]

public struct SolarSystem: Migration {
    let seed: Bool
    public init(seed: Bool = true) {
        self.seed = seed
    }

    public func prepare(on database: Database) -> EventLoopFuture<Void> {
        let all: [Migration]
        if self.seed {
            all = migrations + seeds
        } else {
            all = migrations
        }
        let queue = EventLoopFutureQueue(eventLoop: database.eventLoop)
        _ = queue.append(each: all) { migration in migration.prepare(on: database) }
        _ = queue.append(each: all) { migration in migration.prepareLate(on: database) }
        return queue.append(database.eventLoop.makeSucceededFuture(()), runningOn: .success)
    }

    public func revert(on database: Database) -> EventLoopFuture<Void> {
        let all: [Migration]
        if self.seed {
            all = migrations + seeds
        } else {
            all = migrations
        }
        let queue = EventLoopFutureQueue(eventLoop: database.eventLoop)
        _ = queue.append(each: all.reversed()) { migration in migration.revertLate(on: database) }
        _ = queue.append(each: all.reversed()) { migration in migration.revert(on: database) }
        return queue.append(database.eventLoop.makeSucceededFuture(()), runningOn: .success)
    }
}
