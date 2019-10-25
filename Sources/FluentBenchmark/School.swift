import FluentKit

public final class School: Model {
    public static let schema = "schools"

    @ID(key: "id")
    public var id: Int?

    @Field(key: "name")
    public var name: String

    @Field(key: "pupils")
    public var pupils: Int

    @Parent(key: "city_id")
    public var city: City

    public init() { }

    public init(id: Int? = nil, name: String, pupils: Int, cityID: City.IDValue) {
        self.id = id
        self.name = name
        self.pupils = pupils
        self.$city.id = cityID
    }
}

public struct SchoolMigration: Migration {
    public func prepare(on database: Database) -> EventLoopFuture<Void> {
        return database.schema("schools")
            .field("id", .int, .identifier(auto: true))
            .field("name", .string, .required)
            .field("pupils", .int, .required)
            .field("city_id", .int, .required)
            .create()
    }

    public func revert(on database: Database) -> EventLoopFuture<Void> {
        return database.schema("schools").delete()
    }
}

