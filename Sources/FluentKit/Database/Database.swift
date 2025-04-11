import NIOCore
import Logging

public struct AsyncDatabaseOutputSequence: AsyncSequence, Sendable {
    public typealias Element = any DatabaseOutput

    init() {
    }

    public func makeAsyncIterator() -> AsyncIterator {
        AsyncIterator()
    }

    public struct AsyncIterator: AsyncIteratorProtocol {
        public typealias Element = any DatabaseOutput

        init() {
        }

        public mutating func next() async throws -> (any DatabaseOutput)? {
            nil
        }
    }
}

@available(*, unavailable)
extension AsyncDatabaseOutputSequence.AsyncIterator: Sendable {}

public protocol Database: Sendable {
    var context: DatabaseContext { get }
    
    func execute(
        query: DatabaseQuery
    ) async throws -> AsyncDatabaseOutputSequence

    func execute(
        schema: DatabaseSchema
    ) async throws

    func execute(
        enum: DatabaseEnum
    ) async throws

    var inTransaction: Bool { get }

    func transaction<T>(_ closure: @escaping @Sendable (any Database) async throws -> T) async throws -> T

    func withConnection<T>(_ closure: @escaping @Sendable (any Database) async throws -> T) async throws -> T
}

extension Database {
    public func query<Model>(_ model: Model.Type) -> QueryBuilder<Model>
        where Model: FluentKit.Model
    {
        .init(database: self)
    }
}

extension Database {
    public var configuration: any DatabaseConfiguration {
        self.context.configuration
    }
    
    public var logger: Logger {
        self.context.logger
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
    func shutdown() async
}

public protocol DatabaseConfiguration: Sendable {
    var middleware: [any AnyModelMiddleware] { get set }
    func makeDriver(for databases: Databases) -> any DatabaseDriver
}

public struct DatabaseContext: Sendable {
    public let configuration: any DatabaseConfiguration
    public let logger: Logger
    public let history: QueryHistory?
    public let pageSizeLimit: Int?
    
    public init(
        configuration: any DatabaseConfiguration,
        logger: Logger,
        history: QueryHistory? = nil,
        pageSizeLimit: Int? = nil
    ) {
        self.configuration = configuration
        self.logger = logger
        self.history = history
        self.pageSizeLimit = pageSizeLimit
    }
}

public protocol DatabaseError {
    var isSyntaxError: Bool { get }
    var isConstraintFailure: Bool { get }
    var isConnectionClosed: Bool { get }
}
