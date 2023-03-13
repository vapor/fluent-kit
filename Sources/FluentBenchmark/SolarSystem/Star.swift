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
    
    @Timestamp(key: "deletedAt", on: .delete)
    var deletedAt: Date?

    @Parent(key: "galaxy_id")
    public var galaxy: Galaxy

    @Children(for: \.$star)
    public var planets: [Planet]

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
            .field("deletedAt", .datetime)
            .field("galaxy_id", .uuid, .required, .references("galaxies", "id"))
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
                let toDelete: [Star]
                switch galaxy.name {
                case "Milky Way":
                    let sn1604 = Star(name: "SN 1604")
                    stars = [.init(name: "Sun"), .init(name: "Alpha Centauri"), sn1604]
                    toDelete = [sn1604]
                    
                case "Andromeda":
                    stars = [.init(name: "Alpheratz")]
                    toDelete = []
                default:
                    stars = []
                    toDelete = []
                }
                return galaxy.$stars.create(stars, on: database).flatMap {
                    toDelete.map { $0.delete(on: database) }.flatten(on: database.eventLoop)
                }
            }, on: database.eventLoop)
        }
    }

    public func revert(on database: Database) -> EventLoopFuture<Void> {
        Star.query(on: database).delete(force: true)
    }
}
