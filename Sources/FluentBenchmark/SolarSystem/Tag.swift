import FluentKit
import Foundation
import NIOCore
import XCTest

public final class Tag: Model {
    public static let schema = "tags"

    @ID(key: .id)
    public var id: UUID?

    @Field(key: "name")
    public var name: String

    @Siblings(through: PlanetTag.self, from: \.$tag, to: \.$planet)
    public var planets: [Planet]

    public init() { }

    public init(id: UUID? = nil, name: String) {
        self.id = id
        self.name = name
    }
}

public struct TagMigration: Migration {
    public init() { }

    public func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema("tags")
            .field("id", .uuid, .identifier(auto: false))
            .field("name", .string, .required)
            .create()
    }

    public func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema("tags").delete()
    }
}

public final class TagSeed: Migration {
    public init() { }

    public func prepare(on database: Database) -> EventLoopFuture<Void> {
        .andAllSucceed([
            "Small Rocky", "Gas Giant", "Inhabited"
        ].map {
            Tag(name: $0)
                .create(on: database)
        }, on: database.eventLoop)
    }

    public func revert(on database: Database) -> EventLoopFuture<Void> {
        Tag.query(on: database).delete()
    }
}
