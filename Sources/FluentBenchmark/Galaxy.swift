import struct Foundation.Date
import FluentKit

public final class Galaxy: Model {
    public static let schema = "galaxies"

    public static var migration: Migration {
        return GalaxyMigration()
    }
    
    @ID(key: "id")
    public var id: Int?

    @Field(key: "name")
    public var name: String

    @Children(for: \.$galaxy)
    public var planets: [Planet]

    @Timestamp(key: "deleted_at", on: .delete)
    public var deletedAt: Date?

    public init() { }

    public init(id: Int? = nil, name: String) {
        self.id = id
        self.name = name
    }
}

struct GalaxyMigration: Migration {
    init() {}
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        return database.schema("galaxies")
            .field("id", .int, .identifier(auto: true))
            .field("name", .string, .required)
            .field("deleted_at", .datetime)
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        return database.schema("galaxies").delete()
    }
}
