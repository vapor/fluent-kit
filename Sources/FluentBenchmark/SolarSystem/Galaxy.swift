import FluentKit
import Foundation
import NIOCore
import XCTest

public final class Galaxy: Model {
    public static let schema = "galaxies"
    
    @ID(key: .id)
    public var id: UUID?

    @Field(key: "name")
    public var name: String

    @Children(for: \.$galaxy)
    public var stars: [Star]
    
    @Siblings(through: GalacticJurisdiction.self, from: \.$id.$galaxy, to: \.$id.$jurisdiction)
    public var jurisdictions: [Jurisdiction]

    public init() { }

    public init(id: UUID? = nil, name: String) {
        self.id = id
        self.name = name
    }
}

public struct GalaxyMigration: Migration {
    public init() {}

    public func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema("galaxies")
            .field("id", .uuid, .identifier(auto: false))
            .field("name", .string, .required)
            .create()
    }

    public func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema("galaxies").delete()
    }
}

public struct GalaxySeed: Migration {
    public init() { }

    public func prepare(on database: Database) -> EventLoopFuture<Void> {
        .andAllSucceed([
            "Andromeda",
            "Milky Way",
            "Pinwheel Galaxy",
            "Messier 82"
        ].map {
            Galaxy(name: $0)
                .create(on: database)
        }, on: database.eventLoop)
    }

    public func revert(on database: Database) -> EventLoopFuture<Void> {
        Galaxy.query(on: database).delete()
    }
}
