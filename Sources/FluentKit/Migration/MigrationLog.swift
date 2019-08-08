import Foundation

/// Stores information about `Migration`s that have been run.
public final class MigrationLog: Model, Timestampable {
    public static let entity = "fluent"

    public static var migration: Migration {
        return MigrationLogMigration()
    }

    @ID("id") public var id: Int?
    @Field("name") public var name: String
    @Field("batch") public var batch: Int
    @Field("created_at") public var createdAt: Date?
    @Field("updated_at") public var updatedAt: Date?

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
        return MigrationLog.schema(on: database)
            .field("id", .int, .identifier(auto: true))
            .field("name", .string, .required)
            .field("batch", .int, .required)
            .field("created_at", .datetime)
            .field("updated_at", .datetime)
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        return MigrationLog.schema(on: database).delete()
    }
}
