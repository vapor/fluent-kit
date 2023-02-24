import NIOCore
import Foundation

/// Stores information about `Migration`s that have been run.
public final class MigrationLog: Model {
    public static let schema = "_fluent_migrations"

    public static var migration: Migration {
        return MigrationLogMigration()
    }

    @ID(key: .id)
    public var id: UUID?

    @Field(key: "name")
    public var name: String

    @Field(key: "batch")
    public var batch: Int

    @Timestamp(key: "created_at", on: .create)
    public var createdAt: Date?

    @Timestamp(key: "updated_at", on: .update)
    public var updatedAt: Date?

    public init() { }

    public init(id: IDValue? = nil, name: String, batch: Int) {
        self.id = id
        self.name = name
        self.batch = batch
        self.createdAt = nil
        self.updatedAt = nil
    }
}

private struct MigrationLogMigration: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema("_fluent_migrations")
            .field(.id, .uuid, .identifier(auto: false))
            .field("name", .string, .required)
            .field("batch", .int, .required)
            .field("created_at", .datetime)
            .field("updated_at", .datetime)
            .unique(on: "name")
            .ignoreExisting()
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema("_fluent_migrations").delete()
    }
}
