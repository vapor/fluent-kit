public protocol Database {
    var context: DatabaseContext { get }
    
    func execute(
        query: DatabaseQuery,
        onOutput: @escaping (DatabaseOutput) -> ()
    ) -> EventLoopFuture<Void>

    func execute(
        schema: DatabaseSchema
    ) -> EventLoopFuture<Void>

    func execute(
        enum: DatabaseEnum
    ) -> EventLoopFuture<Void>

    var inTransaction: Bool { get }

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

public protocol DatabaseConfiguration {
    var middleware: [AnyModelMiddleware] { get set }
    func makeDriver(for databases: Databases) -> DatabaseDriver
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
