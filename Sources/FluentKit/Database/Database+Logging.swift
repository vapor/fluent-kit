extension Database {
    public func logging(to logger: Logger) -> Database {
        LoggingOverrideDatabase(database: self, logger: logger)
    }
}

private struct LoggingOverrideDatabase {
    let database: Database
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
        onOutput: @escaping (DatabaseOutput) -> ()
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

    func transaction<T>(_ closure: @escaping (Database) -> EventLoopFuture<T>) -> EventLoopFuture<T> {
        self.database.transaction(closure)
    }
    
    func withConnection<T>(_ closure: @escaping (Database) -> EventLoopFuture<T>) -> EventLoopFuture<T> {
        self.database.withConnection(closure)
    }
}
