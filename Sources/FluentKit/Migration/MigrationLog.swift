import Foundation

/// Stores information about `Migration`s that have been run.
/// This information is used to determine which migrations need to be run
/// when the app boots. It is also used to determine which migrations to revert when
/// using the `RevertCommand`.
public final class MigrationLog: Model {
    /// See `Model`.
    public var entity: String {
        return "fluent"
    }
    
    /// See `Model`.
    public var id: Field<UUID> {
        return self.field("id")
    }
    
    /// The unique name of the migration.
    public var name: Field<String> {
        return self.field("name")
    }
    
    /// The batch number.
    public var batch: Field<Int> {
        return self.field("batch")
    }
    
    /// When this log was created.
    public var createdAt: Field<Date> {
        return self.field("createdAt")
    }
    
    /// When this log was last updated.
    public var updatedAt: Field<Date> {
        return self.field("updatedAt")
    }
    
    public var properties: [Property] {
        return [self.id, self.name, self.batch, self.createdAt, self.updatedAt]
    }
    
    public var storage: ModelStorage
    
    public init(storage: ModelStorage) {
        self.storage = storage
    }
}

private var _migrationLogEntity = "fluent"

