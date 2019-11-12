public protocol Database {
    var logger: Logger { get }
    var context: DatabaseContext { get }
    var eventLoop: EventLoop { get }
    
    func execute(
        query: DatabaseQuery,
        onRow: @escaping (DatabaseRow) -> ()
    ) -> EventLoopFuture<Void>

    func execute(
        schema: DatabaseSchema
    ) -> EventLoopFuture<Void>
}

public protocol DatabaseDriver {
    func makeDatabase(
        logger: Logger,
        context: DatabaseContext,
        on eventLoop: EventLoop
    ) -> Database
    func shutdown()
}

public final class DatabaseContext {
    var middleware: [AnyModelMiddleware]
    
    public init() {
        self.middleware = []
    }
}

public protocol DatabaseError {
    var isSyntaxError: Bool { get }
    var isConstraintFailure: Bool { get }
    var isConnectionClosed: Bool { get }
}
