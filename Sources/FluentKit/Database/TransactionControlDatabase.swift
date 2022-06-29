public protocol TransactionControlDatabase {
    var context: DatabaseContext { get }

    func beginTransaction() -> EventLoopFuture<Void>
    func commitTransaction() -> EventLoopFuture<Void>
    func rollbackTransaction() -> EventLoopFuture<Void>
    
    func withConnection<T>(_ closure: @escaping (TransactionControlDatabase) -> EventLoopFuture<T>) -> EventLoopFuture<T>
}

extension TransactionControlDatabase {
    public var configuration: DatabaseConfiguration {
        self.context.configuration
    }
    
    public var logger: Logger {
        self.context.logger
    }
    
    public var eventLoop: EventLoop {
        self.context.eventLoop
    }

    public var history: QueryHistory? {
        self.context.history
    }

    public var pageSizeLimit: Int? {
        self.context.pageSizeLimit
    }
}
