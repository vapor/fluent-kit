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
public protocol SQLDatabase: Sendable {
    /// The `Logger` used for logging all operations relating to a given database.
    var logger: Logger { get set }

    /// The version number the database reports for itself.
    ///
    /// The version must be provided via a type conforming to the ``SQLDatabaseReportedVersion`` protocol. If the
    /// version number is not applicable (such as for a connection pool dispatch wrapper) or not yet known, `nil` may
    /// be returned. Version numbers may also change at runtime (for example, if a connection is auto-reconnected
    /// after a remote update), or even become unknown again after being known.
    ///
    /// > Note: This version number has nothing to do with SQLKit or the driver implementation for the
    /// > database, nor does it represent any data stored within the database; it is the version of the
    /// > database to which the ``SQLDatabase`` object represents a connection (such as a MySQL server, or
    /// > a linked `libsqlite3` library). The primary motivation for finally adding this property stemmed
    /// > from the desire to enable customizing ``SQLDialect`` configurations based on the actual feature set
    /// > available at runtime, rather than the old solution of hardcoding a "safe" (but limited) baseline.
    var version: (any SQLDatabaseReportedVersion)? { get }

    /// The descriptor for the dialect of SQL supported by the given database.
    ///
    /// The dialect must be provided via a type conforming to the ``SQLDialect`` protocol. It is permitted for
    /// different connections to the same database to report different dialects, although it's unclear how this would
    /// be useful in practice; a dialect that differs based on database version should differentiate based on the
    /// ``version-22wnn`` property instead.
    var dialect: any SQLDialect { get }

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

    /// Requests that the given generic SQL query be serialized and executed on the database, and that
    /// the `onRow` closure be invoked once for each result row the query returns (if any).
    ///
    /// - Parameters:
    ///   - query: An ``SQLExpression`` representing a complete query to execute.
    ///   - onRow: A closure which is invoked once for each result row returned by the query (if any).
    func execute(
        sql query: any SQLExpression,
        _ onRow: @escaping @Sendable (any SQLRow) -> Void
    ) async throws

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
    public func serialize(_ expression: any SQLExpression) -> (sql: String, binds: [any Encodable & Sendable]) {
        var serializer = SQLSerializer(database: self)
        expression.serialize(to: &serializer)
        return (serializer.sql, serializer.binds)
    }
}

extension SQLDatabase {
    /// Return a new ``SQLDatabase`` which is indistinguishable from the original save that its
    /// ``SQLDatabase/logger`` property is replaced by the given `Logger`.
    ///
    /// This has the effect of redirecting logging performed on or by the original database to the
    /// provided `Logger`.
    ///
    /// > Warning: The log redirection applies only to the new ``SQLDatabase`` that is returned from
    /// > this method; logging operations performed on the original (i.e. `self`) are unaffected.
    ///
    /// > Note: Because this method returns a generic ``SQLDatabase``, the type it returns need not be public
    /// > API. Unfortunately, this also means that no inlining or static dispatch of the implementation is
    /// > possible, thus imposing a performance penalty on the use of this otherwise trivial utility.
    ///
    /// - Parameter logger: The new `Logger` to use.
    /// - Returns: A database object which logs to the new `Logger`.
    public func logging(to logger: Logger) -> any SQLDatabase {
        CustomLoggerSQLDatabase(database: self, logger: logger)
    }
}

/// Replaces the `Logger` of an existing ``SQLDatabase`` while forwarding all other properties and methods
/// to the original.
private struct CustomLoggerSQLDatabase<D: SQLDatabase>: SQLDatabase {
    /// The underlying database.
    let database: D

    // See `SQLDatabase.logger`.
    var logger: Logger

    // See `SQLDatabase.version`.
    var version: (any SQLDatabaseReportedVersion)? {
        self.database.version
    }

    // See `SQLDatabase.dialect`.
    var dialect: any SQLDialect {
        self.database.dialect
    }

    // See `SQLDatabase.queryLogLevel`.
    var queryLogLevel: Logger.Level? {
        self.database.queryLogLevel
    }

    // See `SQLDatabase.execute(sql:_:)`.
    func execute(
        sql query: any SQLExpression,
        _ onRow: @escaping @Sendable (any SQLRow) -> Void
    ) async throws {
        try await self.database.execute(sql: query, onRow)
    }

    func withSession<R>(
        _ closure: @escaping @Sendable (any SQLDatabase) async throws -> R
    ) async throws -> R {
        try await self.database.withSession(closure)
    }
}
