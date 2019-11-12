public protocol Database {
    var context: DatabaseContext { get }
    
    func execute(
        query: DatabaseQuery,
        onRow: @escaping (DatabaseRow) -> ()
    ) -> EventLoopFuture<Void>

    func execute(
        schema: DatabaseSchema
    ) -> EventLoopFuture<Void>
}

extension Database {
    public var logger: Logger {
        self.context.logger
    }
    
    public var eventLoop: EventLoop {
        self.context.eventLoop
    }
}

public protocol DatabaseDriver {
    var eventLoopGroup: EventLoopGroup { get }
    func makeDatabase(with context: DatabaseContext) -> Database
    func shutdown()
}

public struct DatabaseContext {
    public let logger: Logger
    public let eventLoop: EventLoop
    public let middleware: [AnyModelMiddleware]
    
    init(logger: Logger, on eventLoop: EventLoop) {
        self.logger = logger
        self.eventLoop = eventLoop
    }
}

public protocol DatabaseError {
    var isSyntaxError: Bool { get }
    var isConstraintFailure: Bool { get }
    var isConnectionClosed: Bool { get }
}
