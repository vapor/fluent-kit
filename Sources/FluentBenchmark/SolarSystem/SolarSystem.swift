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

        return all.reduce(database.eventLoop.makeSucceededVoidFuture()) { f, m in f.flatMap { m.prepare(on: database) } }
    }

    public func revert(on database: any Database) -> EventLoopFuture<Void> {
        let all: [any Migration]
        if self.seed {
            all = migrations + seeds
        } else {
            all = migrations
        }

        return all.reversed().reduce(database.eventLoop.makeSucceededVoidFuture()) { f, m in f.flatMap { m.revert(on: database) } }
    }
}
