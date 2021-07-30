/// `Migration` can assist with database migration. It can choose
/// to create a new database schema for migration, or drop an
/// existing schema. These actions are done in-place, returning no
/// values.
public protocol Migration {
    var name: String { get }
    /// Prepares new database schema for the migration.
    /// - Parameters:
    ///     - database: `Database` to be created.
    /// - returns: An asynchronous `Void`.
    func prepare(on database: Database) -> EventLoopFuture<Void>
    
    /// Drops the database.
    /// - Parameters:
    ///     - database: `Database` to be dropped.
    /// - returns: An asynchronous `Void`.
    func revert(on database: Database) -> EventLoopFuture<Void>
}

extension Migration {
    public var name: String {
        return defaultName
    }

    internal var defaultName: String {
        return String(reflecting: Self.self)
    }
}
