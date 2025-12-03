import FluentKit
import Foundation
import NIOCore
import XCTest

public final class Galaxy: Model, @unchecked Sendable {
    public static let schema = "galaxies"

    @ID
    public var id: UUID?

    @Field(key: "name")
    public var name: String

    @Children(for: \.$galaxy)
    public var stars: [Star]

    @Siblings(through: GalacticJurisdiction.self, from: \.$id.$galaxy, to: \.$id.$jurisdiction)
    public var jurisdictions: [Jurisdiction]

    public init() {}

    public init(id: UUID? = nil, name: String) {
        self.id = id
        self.name = name
    }
}

public struct GalaxyMigration: AsyncMigration {
    public init() {}

    public func prepare(on database: any Database) async throws {
        try await database.schema("galaxies")
            .id()
            .field("name", .string, .required)
            .create()
    }

    public func revert(on database: any Database) async throws {
        try await database.schema("galaxies").delete()
    }
}

public struct GalaxySeed: AsyncMigration {
    public init() {}

    public func prepare(on database: any Database) async throws {
        try await [
            "Andromeda",
            "Milky Way",
            "Pinwheel Galaxy",
            "Messier 82",
        ]
        .map { Galaxy(name: $0) }
        .create(on: database)
    }

    public func revert(on database: any Database) async throws {
        try await Galaxy.query(on: database).delete()
    }
}
