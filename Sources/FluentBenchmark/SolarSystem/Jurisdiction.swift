import FluentKit

public final class Jurisdiction: Model {
    public static let schema = "jurisdictions"
    
    @ID(key: .id)
    public var id: UUID?
    
    @Field(key: "title")
    public var title: String
    
    @Siblings(through: GalacticJurisdiction.self, from: \.$id.$jurisdiction, to: \.$id.$galaxy)
    public var galaxies: [Galaxy]
    
    public init() {}
    
    public init(id: IDValue? = nil, title: String) {
        self.id = id
        self.title = title
    }
}

public struct JurisdictionMigration: Migration {
    public init() {}
    
    public func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema(Jurisdiction.schema)
            .field(.id, .uuid, .identifier(auto: false), .required)
            .field("title", .string, .required)
            .unique(on: "title")
            .create()
    }
    
    public func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema(Jurisdiction.schema)
            .delete()
    }
}

public struct JurisdictionSeed: Migration {
    public init() {}
    
    public func prepare(on database: Database) -> EventLoopFuture<Void> {
        [
            Jurisdiction(title: "Old"),
            Jurisdiction(title: "Corporate"),
            Jurisdiction(title: "Military"),
            Jurisdiction(title: "None"),
            Jurisdiction(title: "Q"),
        ]
        .create(on: database)
    }
    
    public func revert(on database: Database) -> EventLoopFuture<Void> {
        Jurisdiction.query(on: database)
            .delete()
    }
}
