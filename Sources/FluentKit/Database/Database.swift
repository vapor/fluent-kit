import NIOCore
import Logging

public protocol Database: Sendable {
    var context: DatabaseContext { get }
    
    func execute(
        query: DatabaseQuery,
        onOutput: @escaping @Sendable (any DatabaseOutput) -> ()
    ) -> EventLoopFuture<Void>

    func execute(
        schema: DatabaseSchema
    ) -> EventLoopFuture<Void>

    func execute(
        enum: DatabaseEnum
    ) -> EventLoopFuture<Void>

    var inTransaction: Bool { get }

    func transaction<T>(_ closure: @escaping @Sendable (any Database) -> EventLoopFuture<T>) -> EventLoopFuture<T>
    
    func withConnection<T>(_ closure: @escaping @Sendable (any Database) -> EventLoopFuture<T>) -> EventLoopFuture<T>
}

extension Database {
    public func query<Model>(_ model: Model.Type) -> QueryBuilder<Model>
        where Model: FluentKit.Model
    {
        return .init(database: self)
    }
}

extension Database {
    public var configuration: any DatabaseConfiguration {
        self.context.configuration
    }
    
    public var logger: Logger {
        self.context.logger
    }
    
    public var eventLoop: any EventLoop {
        self.context.eventLoop
    }

    public var history: QueryHistory? {
        self.context.history
    }

    public var pageSizeLimit: Int? {
        self.context.pageSizeLimit
    }
}

public protocol DatabaseDriver: Sendable {
    func makeDatabase(with context: DatabaseContext) -> any Database
    func shutdown()
}

public protocol DatabaseConfiguration: Sendable {
    var middleware: [any AnyModelMiddleware] { get set }
    func makeDriver(for databases: Databases) -> any DatabaseDriver
}

public struct DatabaseContext {
    public let configuration: any DatabaseConfiguration
    public let logger: Logger
    public let eventLoop: any EventLoop
    public let history: QueryHistory?
    public let pageSizeLimit: Int?
    
    public init(
        configuration: any DatabaseConfiguration,
        logger: Logger,
        eventLoop: any EventLoop,
        history: QueryHistory? = nil,
        pageSizeLimit: Int? = nil
    ) {
        self.configuration = configuration
        self.logger = logger
        self.eventLoop = eventLoop
        self.history = history
        self.pageSizeLimit = pageSizeLimit
    }
}

public protocol DatabaseError {
    var isSyntaxError: Bool { get }
    var isConstraintFailure: Bool { get }
    var isConnectionClosed: Bool { get }
}
