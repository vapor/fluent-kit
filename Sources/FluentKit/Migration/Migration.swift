public protocol Migration {
    var name: String { get }
    func prepare(on database: Database) -> EventLoopFuture<Void>
    func revert(on database: Database) -> EventLoopFuture<Void>
}

extension Migration {
    public var name: String {
        return "\(Self.self)"
    }
    
}

public protocol GenericMigration: Migration {
    associatedtype MigrationModel: Model
}

extension GenericMigration {
    public func schema(for database: Database) -> SchemaBuilder {
        database.schema(MigrationModel.schema)
    }
}

//extension Model {
//    public static func autoMigration() -> Migration {
//        return AutoMigration<Self>()
//    }
//}
//
//private final class AutoMigration<Model>: Migration
//    where Model: FluentKit.Model
//{
//    init() { }
//    var name: String {
//        return "\(Model.self)"
//    }
//    
//    func prepare(on database: Database) -> EventLoopFuture<Void> {
//        return database.schema(Model.self).auto().create()
//    }
//    
//    func revert(on database: Database) -> EventLoopFuture<Void> {
//        return database.schema(Model.self).delete()
//    }
//}
