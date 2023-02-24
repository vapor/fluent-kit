import AsyncKit
import FluentKit
import NIOCore

private let migrations: [Migration] = [
    GalaxyMigration(),
    StarMigration(),
    PlanetMigration(),
    GovernorMigration(),
    MoonMigration(),
    TagMigration(),
    PlanetTagMigration(),
]

private let seeds: [Migration] = [
    GalaxySeed(),
    StarSeed(),
    PlanetSeed(),
    GovernorSeed(),
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

        return all.sequencedFlatMapEach(on: database.eventLoop) { $0.prepare(on: database) }
    }

    public func revert(on database: Database) -> EventLoopFuture<Void> {
        let all: [Migration]
        if self.seed {
            all = migrations + seeds
        } else {
            all = migrations
        }

        return all.reversed().sequencedFlatMapEach(on: database.eventLoop) { $0.revert(on: database) }
    }
}
