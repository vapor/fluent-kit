import Foundation

/// Stores information about `Migration`s that have been run.
/// This information is used to determine which migrations need to be run
/// when the app boots. It is also used to determine which migrations to revert when
/// using the `RevertCommand`.
public struct MigrationLog: Model, Timestampable {
    public static var shared = MigrationLog()
    public static var entity = "fluent"
    public let id = Field<Int?>("id")
    public let name = Field<String>("name")
    public let batch = Field<Int>("batch")
    public let createdAt = Field<Date?>("createdAt")
    public let updatedAt = Field<Date?>("updatedAt")
}
