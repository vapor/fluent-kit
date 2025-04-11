import Logging
import SQLKit

extension Database {
    public func logging(to logger: Logger) -> any Database {
        LoggingOverrideDatabase(database: self, logger: logger)
    }
}

private struct LoggingOverrideDatabase<D: Database> {
    let database: D
    var logger: Logger
}

extension LoggingOverrideDatabase: Database {
    var context: DatabaseContext {
        .init(
            configuration: self.database.context.configuration,
            logger: self.logger,
            history: self.database.context.history
        )
    }
    
    func execute(
        query: DatabaseQuery
    ) async throws -> AsyncDatabaseOutputSequence {
        try await self.database.execute(query: query)
    }

    func execute(
        schema: DatabaseSchema
    ) async throws {
        try await self.database.execute(schema: schema)
    }

    func execute(
        enum: DatabaseEnum
    ) async throws {
        try await self.database.execute(enum: `enum`)
    }

    var inTransaction: Bool {
        self.database.inTransaction
    }

    func transaction<T>(_ closure: @escaping @Sendable (any Database) async throws -> T) async throws -> T {
        try await self.database.transaction(closure)
    }
    
    func withConnection<T>(_ closure: @escaping @Sendable (any Database) async throws -> T) async throws -> T {
        try await self.database.withConnection(closure)
    }
}

extension LoggingOverrideDatabase: SQLDatabase where D: SQLDatabase {
    func execute(sql query: any SQLExpression, _ onRow: @escaping @Sendable (any SQLRow) -> ()) async throws  {
        try await self.database.execute(sql: query, onRow)
    }
    func withSession<R>(_ closure: @escaping @Sendable (any SQLDatabase) async throws -> R) async throws -> R {
        try await self.database.withSession(closure)
    }
    var dialect: any SQLDialect { self.database.dialect }
    var version: (any SQLDatabaseReportedVersion)? { self.database.version }
    var queryLogLevel: Logger.Level? { self.database.queryLogLevel }
}
