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

public final class DatabaseContext {
    public let logger: Logger
    public let eventLoop: EventLoop
    var middleware: [AnyModelMiddleware]
    
    public init(
        logger: Logger = .init(label: "codes.vapor.fluent"),
        on eventLoop: EventLoop
    ) {
        self.logger = logger
        self.eventLoop = eventLoop
        self.middleware = []
    }
}

public protocol DatabaseError {
    var isSyntaxError: Bool { get }
    var isConstraintFailure: Bool { get }
    var isConnectionClosed: Bool { get }
}
