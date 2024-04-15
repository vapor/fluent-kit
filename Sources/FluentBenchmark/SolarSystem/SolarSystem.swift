import AsyncKit
import FluentKit
import NIOCore

private let migrations: [any Migration] = [
    GalaxyMigration(),
    StarMigration(),
    PlanetMigration(),
    GovernorMigration(),
    MoonMigration(),
    TagMigration(),
    PlanetTagMigration(),
]

private let seeds: [any Migration] = [
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

    public func prepare(on database: any Database) -> EventLoopFuture<Void> {
        let all: [any Migration]
        if self.seed {
            all = migrations + seeds
        } else {
            all = migrations
        }

        return all.sequencedFlatMapEach(on: database.eventLoop) { $0.prepare(on: database) }
    }

    public func revert(on database: any Database) -> EventLoopFuture<Void> {
        let all: [any Migration]
        if self.seed {
            all = migrations + seeds
        } else {
            all = migrations
        }

        return all.reversed().sequencedFlatMapEach(on: database.eventLoop) { $0.revert(on: database) }
    }
}
