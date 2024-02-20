import FluentKit
import Foundation
import NIOCore
import XCTest

public final class Star: Model {
    public static let schema = "stars"

    @ID(key: .id)
    public var id: UUID?

    @Field(key: "name")
    public var name: String

    @Parent(key: "galaxy_id")
    public var galaxy: Galaxy

    @Children(for: \.$star)
    public var planets: [Planet]
    
    @Timestamp(key: "deleted_at", on: .delete)
    var deletedAt: Date?

    public init() { }

    public init(id: IDValue? = nil, name: String) {
        self.id = id
        self.name = name
    }
}

public struct StarMigration: Migration {
    public func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema("stars")
            .field("id", .uuid, .identifier(auto: false))
            .field("name", .string, .required)
            .field("galaxy_id", .uuid, .required, .references("galaxies", "id"))
            .field("deleted_at", .datetime)
            .create()
    }

    public func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema("stars").delete()
    }
}

public final class StarSeed: Migration {
    public init() { }

    public func prepare(on database: Database) -> EventLoopFuture<Void> {
        Galaxy.query(on: database).all().flatMap { galaxies in
            .andAllSucceed(galaxies.map { galaxy in
                let stars: [Star]
                switch galaxy.name {
                case "Milky Way":
                    stars = [.init(name: "Sun"), .init(name: "Alpha Centauri")]
                case "Andromeda":
                    stars = [.init(name: "Alpheratz")]
                default:
                    stars = []
                }
                return galaxy.$stars.create(stars, on: database)
            }, on: database.eventLoop)
        }
    }

    public func revert(on database: Database) -> EventLoopFuture<Void> {
        Star.query(on: database).delete(force: true)
    }
}
