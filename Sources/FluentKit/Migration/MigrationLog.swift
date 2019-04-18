import Foundation

/// Stores information about `Migration`s that have been run.
/// This information is used to determine which migrations need to be run
/// when the app boots. It is also used to determine which migrations to revert when
/// using the `RevertCommand`.
public final class MigrationLog: Model {
    public typealias ID = Int

    public static var entity = "fluent"
    public var id = Field<Int>()
    public var name = Field<String>()
    public var batch = Field<Int>()
    public var createdAt = Field<Date>()
    public var updatedAt = Field<Date>()

    public init(id: Int? = nil, name: String, batch: Int, createdAt: Date? = nil, updatedAt: Date? = nil) {
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
        fatalError()
    }

    public static func name(for keyPath: PartialKeyPath<MigrationLog>) -> String? {
        switch keyPath {
        case \MigrationLog.id: return "id"
        case \MigrationLog.name: return "name"
        case \MigrationLog.batch: return "batch"
        case \MigrationLog.createdAt: return "createdAt"
        case \MigrationLog.updatedAt: return "updatedAt"
        default: return nil
        }
    }

    public static func fields() -> [(PartialKeyPath<MigrationLog>, Any.Type)] {
        return [
            (\MigrationLog.id as PartialKeyPath<MigrationLog>, Int.self),
            (\MigrationLog.name as PartialKeyPath<MigrationLog>, String.self),
            (\MigrationLog.batch as PartialKeyPath<MigrationLog>, Int.self),
            (\MigrationLog.createdAt as PartialKeyPath<MigrationLog>, Date.self),
            (\MigrationLog.updatedAt as PartialKeyPath<MigrationLog>, Date.self),
        ]
    }

    public static func dataType(for keyPath: PartialKeyPath<MigrationLog>) -> DatabaseSchema.DataType? {
        return nil
    }

    public static func constraints(for keyPath: PartialKeyPath<MigrationLog>) -> [DatabaseSchema.FieldConstraint]? {
        return nil
    }
}
