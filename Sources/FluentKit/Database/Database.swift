public protocol Database {
    var context: DatabaseContext { get }
    
    func execute(
        query: DatabaseQuery,
        onRow: @escaping (DatabaseRow) -> ()
    ) -> EventLoopFuture<Void>

    func execute(
        schema: DatabaseSchema
    ) -> EventLoopFuture<Void>

    func transaction<T>(_ closure: @escaping (Database) -> EventLoopFuture<T>) -> EventLoopFuture<T>
    
    func withConnection<T>(_ closure: @escaping (Database) -> EventLoopFuture<T>) -> EventLoopFuture<T>
}

extension Database {
    public func query<Model>(_ model: Model.Type) -> QueryBuilder<Model>
        where Model: FluentKit.Model
    {
        return .init(database: self)
    }
}

extension Database {
    public var configuration: DatabaseConfiguration {
        self.context.configuration
    }
    
    public var logger: Logger {
        self.context.logger
    }
    
    public var eventLoop: EventLoop {
        self.context.eventLoop
    }
}

public protocol DatabaseDriver {
    func makeDatabase(with context: DatabaseContext) -> Database
    func shutdown()
}

public final class DatabaseConfiguration {
    public var middleware: [AnyModelMiddleware]
    public init() {
        self.middleware = []
    }
}

public struct DatabaseContext {
    public let configuration: DatabaseConfiguration
    public let logger: Logger
    public let eventLoop: EventLoop
    
    public init(
        configuration: DatabaseConfiguration,
        logger: Logger,
        eventLoop: EventLoop
    ) {
        self.configuration = configuration
        self.logger = logger
        self.eventLoop = eventLoop
    }
}

public protocol DatabaseError {
    var isSyntaxError: Bool { get }
    var isConstraintFailure: Bool { get }
    var isConnectionClosed: Bool { get }
}
