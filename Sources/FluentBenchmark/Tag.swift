import FluentKit

public final class Tag: Model {
    public class func schema() -> String { "tags" }

    @ID(key: "id")
    public var id: Int?

    @Field(key: "name")
    public var name: String

    @Siblings(through: PlanetTag.self, from: \.$tag, to: \.$planet)
    public var planets: [Planet]

    public init() { }

    public init(id: Int? = nil, name: String) {
        self.id = id
        self.name = name
    }
}

public struct TagMigration: Migration {
    public func prepare(on database: Database) -> EventLoopFuture<Void> {
        return database.schema("tags")
            .field("id", .int, .identifier(auto: true))
            .field("name", .string, .required)
            .create()
    }

    public func revert(on database: Database) -> EventLoopFuture<Void> {
        return database.schema("tags").delete()
    }
}
