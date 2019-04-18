import Foundation

/// Stores information about `Migration`s that have been run.
/// This information is used to determine which migrations need to be run
/// when the app boots. It is also used to determine which migrations to revert when
/// using the `RevertCommand`.
public final class MigrationLog: Model {
    public typealias ID = Int

    public static var entity = "fluent"
    public var id = Field<Int>("id")
    public var name = Field<String>("name")
    public var batch = Field<Int>("batch")
    public var createdAt = Field<Date>("createdAt")
    public var updatedAt = Field<Date>("updatedAt")
    public let storage: ModelStorage

    public convenience init(id: Int? = nil, name: String, batch: Int, createdAt: Date? = nil, updatedAt: Date? = nil) {
        self.init()
        if let id = id {
            self.id.value = id
        }
        self.name.value = name
        self.batch.value = batch
        #warning("TODO: Timestampable")
        if let createdAt = createdAt {
            self.createdAt.value = createdAt
        }
        if let updatedAt = updatedAt {
            self.updatedAt.value = updatedAt
        }
    }

    public init(storage: ModelStorage) {
        self.storage = storage
    }
}
