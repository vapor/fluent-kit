import Foundation

/// Stores information about `Migration`s that have been run.
public final class MigrationLog: Model, Timestampable {
    public static let entity = "fluent"

    @Field public var id: Int?
    @Field public var name: String
    @Field public var batch: Int
    @Field public var createdAt: Date?
    @Field public var updatedAt: Date?

    public init() {
        self.initialize()
    }

    public convenience init(id: Int? = nil, name: String, batch: Int) {
        self.init()
        self.id = id
        self.name = name
        self.batch = batch
        self.createdAt = nil
        self.updatedAt = nil
    }
}
