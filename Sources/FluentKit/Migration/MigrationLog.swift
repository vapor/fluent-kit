import Foundation

/// Stores information about `Migration`s that have been run.
/// This information is used to determine which migrations need to be run
/// when the app boots. It is also used to determine which migrations to revert when
/// using the `RevertCommand`.
public final class MigrationLog: Model, Timestampable {
    public static let entity = "fluent"

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
    }
}
