import FluentKit

public final class City: Model {
    public static let schema = "cities"

    @ID(key: "id")
    public var id: Int?

    @Field(key: "name")
    public var name: String

    @Field(key: "averageNumberOfPupils")
    public var averageNumberOfPupils: Int

    @Children(from: \.$city)
    public var schools: [School]

    public init() { }

    public init(id: Int? = nil, name: String, averageNumberOfPupils: Int) {
        self.id = id
        self.name = name
        self.averageNumberOfPupils = averageNumberOfPupils
    }
}

public struct CityMigration: Migration {
    public func prepare(on database: Database) -> EventLoopFuture<Void> {
        return database.schema("cities")
            .field("id", .int, .identifier(auto: true))
            .field("name", .string, .required)
            .field("averageNumberOfPupils", .int, .required)
            .create()
    }

    public func revert(on database: Database) -> EventLoopFuture<Void> {
        return database.schema("cities").delete()
    }
}

