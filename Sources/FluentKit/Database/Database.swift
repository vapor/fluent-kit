public protocol Database {
    var eventLoop: EventLoop { get }
    
    func execute(
        _ query: DatabaseQuery,
        _ onOutput: @escaping (DatabaseOutput) throws -> ()
    ) -> EventLoopFuture<Void>
    
    func execute(_ schema: DatabaseSchema) -> EventLoopFuture<Void>
    
    func close() -> EventLoopFuture<Void>
    
    func withConnection<T>(_ closure: @escaping (Database) -> EventLoopFuture<T>) -> EventLoopFuture<T>
}

public protocol DatabaseError {
    var isSyntaxError: Bool { get }
    var isConstraintFailure: Bool { get }
    var isConnectionClosed: Bool { get }
}
