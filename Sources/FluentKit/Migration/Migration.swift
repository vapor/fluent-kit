/// Fluent's `Migration` can handle database migrations, which can include
/// adding new table, changing existing tables or adding
/// seed data. These actions are executed only once.
public protocol Migration {
    
    /// The name of the migration which Fluent uses to track the state of.
    var name: String { get }
    
    /// Called when a migration is executed.
    /// - Parameters:
    ///     - database: `Database` to run the migration on,
    /// - returns: An asynchronous `Void`.
    
    func prepare(on database: Database) -> EventLoopFuture<Void>
    
    /// Called when the changes from a migration are reverted.
    /// - Parameters:
    ///     - database: `Database` to revert the migration on.
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
