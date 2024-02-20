import NIOCore

/// Protocol for describing a database that allows fine-grained control over transcactions
/// when you need more control than provided by ``Database/transaction(_:)-1x3ds``
///
/// ⚠️ **WARNING**: it is the developer's responsiblity to get hold of a ``Database``,
/// execute the transaction functions on that connection, and ensure that the functions aren't called across
/// different conenctions. You are also responsible for ensuring that you commit or rollback queries
/// when you're ready.
///
/// Do not mix these functions and `Database.transaction(_:)`.
public protocol TransactionControlDatabase: Database {
    /// Start the transaction on the current connection. This is equivalent to an SQL `BEGIN`
    /// - Returns: future `Void` when the transaction has been started
    func beginTransaction() -> EventLoopFuture<Void>

    /// Commit the queries executed for the transaction and write them to the database
    /// This is equivalent to an SQL `COMMIT`
    /// - Returns: future `Void` when the transaction has been committed
    func commitTransaction() -> EventLoopFuture<Void>

    /// Rollback the current transaction's queries. You may want to trigger this when handling an error
    /// when trying to create models.
    /// This is equivalent to an SQL `ROLLBACK`
    /// - Returns: future `Void` when the transaction has been rollbacked
    func rollbackTransaction() -> EventLoopFuture<Void>
}
