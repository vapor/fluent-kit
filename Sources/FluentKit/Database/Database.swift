public protocol Database {
    var eventLoop: EventLoop { get }
    
    func execute(
        _ query: DatabaseQuery,
        _ onOutput: @escaping (DatabaseOutput) throws -> ()
    ) -> EventLoopFuture<Void>
    
    func execute(_ schema: DatabaseSchema) -> EventLoopFuture<Void>
    
    func close() -> EventLoopFuture<Void>
    
    func transaction<T>(_ closure: @escaping (Database) -> EventLoopFuture<T>) -> EventLoopFuture<T>
}

public protocol DatabaseError {
    #warning("TODO: add useful properties like duplicate key constraint, syntax error, conn closed, etc.")
}
