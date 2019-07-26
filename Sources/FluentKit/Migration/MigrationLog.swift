import Foundation

/// Stores information about `Migration`s that have been run.
public final class MigrationLog: Model, Timestampable {
    public static let entity = "fluent"

    public static var migration: Migration {
        return MigrationLogMigration()
    }

    @Field public var id: Int?
    @Field public var name: String
    @Field public var batch: Int
    @Field public var createdAt: Date?
    @Field public var updatedAt: Date?

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
            .field(\.$id, .int, .identifier(auto: true))
            .field(\.$name, .string, .required)
            .field(\.$batch, .int, .required)
            .field(\.$createdAt, .date)
            .field(\.$updatedAt, .date)
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        return MigrationLog.schema(on: database).delete()
    }
}
