import NIOCore
import Logging
import SQLKit

extension Database {
    public func logging(to logger: Logger) -> any Database {
        LoggingOverrideDatabase(database: self, logger: logger)
    }
}

private struct LoggingOverrideDatabase<D: Database> {
    let database: D
    let logger: Logger
}

extension LoggingOverrideDatabase: Database {
    var context: DatabaseContext {
        .init(
            configuration: self.database.context.configuration,
            logger: self.logger,
            eventLoop: self.database.context.eventLoop,
            history: self.database.context.history
        )
    }
    
    func execute(
        query: DatabaseQuery,
        onOutput: @escaping @Sendable (any DatabaseOutput) -> ()
    ) -> EventLoopFuture<Void> {
        self.database.execute(query: query, onOutput: onOutput)
    }

    func execute(
        schema: DatabaseSchema
    ) -> EventLoopFuture<Void> {
        self.database.execute(schema: schema)
    }

    func execute(
        enum: DatabaseEnum
    ) -> EventLoopFuture<Void> {
        self.database.execute(enum: `enum`)
    }

    var inTransaction: Bool {
        self.database.inTransaction
    }

    func transaction<T>(_ closure: @escaping @Sendable (any Database) -> EventLoopFuture<T>) -> EventLoopFuture<T> {
        self.database.transaction(closure)
    }
    
    func withConnection<T>(_ closure: @escaping @Sendable (any Database) -> EventLoopFuture<T>) -> EventLoopFuture<T> {
        self.database.withConnection(closure)
    }
}

extension LoggingOverrideDatabase: SQLDatabase where D: SQLDatabase {
    func execute(sql query: any SQLExpression, _ onRow: @escaping @Sendable (any SQLRow) -> ()) -> EventLoopFuture<Void> {
        self.database.execute(sql: query, onRow)
    }
    func execute(sql query: any SQLExpression, _ onRow: @escaping @Sendable (any SQLRow) -> ()) async throws {
        try await self.database.execute(sql: query, onRow)
    }
    func withSession<R>(_ closure: @escaping @Sendable (any SQLDatabase) async throws -> R) async throws -> R {
        try await self.database.withSession(closure)
    }
    var dialect: any SQLDialect { self.database.dialect }
    var version: (any SQLDatabaseReportedVersion)? { self.database.version }
    var queryLogLevel: Logger.Level? { self.database.queryLogLevel }
}
