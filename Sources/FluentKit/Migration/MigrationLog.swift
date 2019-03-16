import Foundation

/// Stores information about `Migration`s that have been run.
/// This information is used to determine which migrations need to be run
/// when the app boots. It is also used to determine which migrations to revert when
/// using the `RevertCommand`.
public final class MigrationLog: Model {
    public struct Properties: ModelProperties {
        public let id = Field<Int>("id")
        public let name = Field<String>("name")
        public let batch = Field<Int>("batch")
        public let createdAt = Field<Date>("createdAt")
        public let updatedAt = Field<Date>("updatedAt")
    }
    
    public static let entity = "fluent"
    public static let properties = Properties()
    
    public var storage: Storage
    public init(storage: Storage) {
        self.storage = storage
    }
}

private var _migrationLogEntity = "fluent"
