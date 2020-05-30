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

        return EventLoopFutureQueue(eventLoop: database.eventLoop).append(each: all) { $0.prepare(on: database) }
    }

    public func revert(on database: Database) -> EventLoopFuture<Void> {
        let all: [Migration]
        if self.seed {
            all = migrations + seeds
        } else {
            all = migrations
        }

        return EventLoopFutureQueue(eventLoop: database.eventLoop).append(each: all.reversed()) { $0.revert(on: database) }
    }
}
