import FluentKit
import Foundation
import NIOCore
import XCTest

public final class Star: Model, @unchecked Sendable {
    public static let schema = "stars"

    @ID
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

    public init(id: IDValue? = nil, name: String, galaxyId: Galaxy.IDValue? = nil) {
        self.id = id
        self.name = name
        if let galaxyId {
            self.$galaxy.id = galaxyId
        }
    }
}

public struct StarMigration: AsyncMigration {
    public func prepare(on database: any Database) async throws {
        try await database.schema("stars")
            .id()
            .field("name", .string, .required)
            .field("galaxy_id", .uuid, .required, .references("galaxies", "id"))
            .field("deleted_at", .datetime)
            .create()
    }

    public func revert(on database: any Database) async throws {
        try await database.schema("stars").delete()
    }
}

public final class StarSeed: AsyncMigration {
    public init() {}

    public func prepare(on database: any Database) async throws {
        var stars: [Star] = []
        
        for galaxy in try await Galaxy.query(on: database).all() {
            switch galaxy.name {
            case "Milky Way":
                stars.append(contentsOf: [
                    .init(name: "Sol", galaxyId: galaxy.id!),
                    .init(name: "Alpha Centauri", galaxyId: galaxy.id!)
                ])
            case "Andromeda":
                stars.append(.init(name: "Alpheratz", galaxyId: galaxy.id!))
            default:
                break
            }
        }
        try await stars.create(on: database)
    }

    public func revert(on database: any Database) async throws {
        try await Star.query(on: database).delete(force: true)
    }
}
