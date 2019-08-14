import Foundation

/// Stores information about `Migration`s that have been run.
public final class MigrationLog: Model {
    public static let schema = "fluent"

    public static var migration: Migration {
        return MigrationLogMigration()
    }

    @ID(key: "id")
    public var id: Int?

    @Field(key: "name")
    public var name: String

    @Field(key: "batch")
    public var batch: Int

    @Timestamp(key: "created_at", on: .create)
    public var createdAt: Date?

    @Timestamp(key: "updated_at", on: .update)
    public var updatedAt: Date?

    public init() { }

    public init(id: Int? = nil, name: String, batch: Int) {
        self.id = id
        self.name = name
        self.batch = batch
        self.createdAt = nil
        self.updatedAt = nil
    }
}

private final class MigrationLogMigration: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        return database.schema("fluent")
            .field("id", .int, .identifier(auto: true))
            .field("name", .string, .required)
            .field("batch", .int, .required)
            .field("created_at", .datetime)
            .field("updated_at", .datetime)
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        return database.schema("fluent").delete()
    }
}
