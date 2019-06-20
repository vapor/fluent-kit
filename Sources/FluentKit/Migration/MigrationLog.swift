import Foundation

/// Stores information about `Migration`s that have been run.
public final class MigrationLog: Model, Timestampable {
    public static let entity = "fluent"

    @ID public var id: Int?
    @Field public var name: String
    @Field public var batch: Int
    @Field public var createdAt: Date?
    @Field public var updatedAt: Date?

    public init() { }

    public init(name: String, batch: Int) {
        self.name = name
        self.batch = batch
        self.createdAt = nil
        self.updatedAt = nil
    }
}
