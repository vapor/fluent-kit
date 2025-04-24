import struct Logging.Logger

/// The common interface to SQLKit for both drivers and client code.
///
/// ``SQLDatabase`` is the core of an SQLKit driver and the primary entry point for user code. This common interface
/// provides the information and behaviors necessary to define and leverage the package's functionality.
///
/// Conformances to ``SQLDatabase`` are typically provided by an external database-specific driver
/// package, alongside several wrapper types for handling connection logic and other details.
/// A driver package must at minimum provide concrete implementations of ``SQLDatabase``, ``SQLDialect``,
/// and ``SQLRow``.
///
/// The API described by the base ``SQLDatabase`` protocol is low-level, meant for SQLKit drivers to
/// implement; most users will not need to interact with these APIs directly. The high-level starting point
/// for SQLKit is ``SQLQueryBuilder``; the various query builders provide extension methods on ``SQLDatabase``
/// which are the intended public interface.
///
/// For comparison, this is an example of using ``SQLDatabase`` and ``SQLExpression``s directly:
///
/// ```swift
/// let database: SQLDatabase = ...
///
/// var select = SQLSelect()
///
/// select.columns = [SQLColumn(SQLObjectIdentifier("x"))]
/// select.tables = [SQLObjectIdentifier("y")]
/// select.predicate = SQLBinaryExpression(
///     left: SQLColumn(SQLObjectIdentifier("z")),
///     op: SQLBinaryOperator.equal,
///     right: SQLLiteral.numeric("1")
/// )
///
/// nonisolated(unsafe) var resultRows: [SQLRow] = []
///
/// try await database.execute(sql: select, { resultRows.append($0) })
/// // Executed query: SELECT x FROM y WHERE z = 1
///
/// var resultValues: [Int] = try resultRows.map {
///     try $0.decode(column: "x", as: Int.self)
/// }
/// ```
///
/// And this is the same example, written to make use of ``SQLSelectBuilder``:
///
/// ```swift
/// let database: SQLDatabase = ...
/// let resultValues: [Int] = try await database.select()
///     .column("x")
///     .from("y")
///     .where("z", .equal, 1)
///     .all(decodingColumn: "x", as: Int.self)
/// ```
public protocol SQLDatabase {
    /// The type of an `AsyncSequence` whose elements conform to ``SQLRow`` and which throws `any Error`, used by
    /// this database to stream query results.
    ///
    /// > Note: The `Failure == any Error` requirement is not enforced due to the restrictive availability of the
    /// > `AsyncSequence.Failure` associated type.
    associatedtype AsyncRowSequence: AsyncSequence
        where AsyncRowSequence.Element: SQLRow

    /// A type which conforms to ``SQLDialect``, returned by this database when its dialect is requested.
    associatedtype Dialect: SQLDialect

    /// The `Logger` used for logging all operations relating to this database.
    var logger: Logger { get }

    /// The descriptor for the dialect of SQL supported by the given database.
    ///
    /// The dialect must be provided via a type conforming to the ``SQLDialect`` protocol. It is permitted for
    /// different connections to the same database to report different dialects, although it's unclear how this would
    /// be useful in practice.
    var dialect: Dialect { get }

    /// The logging level used for reporting queries run on the given database to the database's logger.
    /// Defaults to `.debug`.
    ///
    /// This log level applies _only_ to logging the serialized SQL text and bound parameter values (if
    /// any) of queries; it does not affect any logging performed by the underlying driver or any other
    /// subsystem. If the value is `nil`, query logging is disabled.
    ///
    /// > Important: Conforming drivers must provide a means to configure this value and to use the default
    /// > `.debug` level if no explicit value is provided. It is also the responsibility of the driver to
    /// > actually perform the query logging, including respecting the logging level.
    /// >
    /// > The lack of enforcement of these requirements is obviously less than ideal, but for the moment
    /// > it's unavoidable, as there are no direct entry points to SQLKit without a driver.
    var queryLogLevel: Logger.Level? { get }

    /// Requests that the given generic SQL query be serialized and executed on the database.
    ///
    /// - Parameters:
    ///   - query: An ``SQLExpression`` representing a complete query to execute.
    /// - Returns: An `AsyncRowSequence` containing the query's results, if any.
    func execute(
        sql query: some SQLExpression
    ) async throws -> AsyncRowSequence

    /// Requests the provided closure be called with a database which is guaranteed to represent a single
    /// "session", suitable for e.g. executing a series of queries representing a transaction.
    ///
    /// This method is provided for the benefit of SQLKit drivers which vend concrete database objects which may not
    /// necessarily always execute consecutive queries in the same remote context, such as in the case of connection
    /// pooling or multiplexing. The default implementation simply passes `self` to the closure; it is the
    /// responsibility of individual drivers to do otherwise as needed.
    ///
    /// - Parameter closure: A closure to invoke. The single parameter shall be an implementation of ``SQLDatabase``
    ///   which represents a single "session". Implementations may pass the same database on which this method was
    ///   originally invoked.
    func withSession<R>(
        _ closure: @escaping @Sendable (any SQLDatabase) async throws -> R
    ) async throws -> R
}

extension SQLDatabase {
    /// Serialize an arbitrary ``SQLExpression`` using the database's dialect.
    ///
    /// The expression need not represent a complete query. Serialization transforms the expression into:
    ///
    /// 1. A string containing raw SQL text rendered in the database's dialect, and,
    /// 2. A potentially empty array of values for any bound parameters referenced by the query.
    public func serialize(_ expression: some SQLExpression) -> (sql: String, binds: [any Encodable & Sendable]) {
        var serializer = SQLSerializer(database: self)
        expression.serialize(to: &serializer)
        return (serializer.sql, serializer.binds)
    }
}
