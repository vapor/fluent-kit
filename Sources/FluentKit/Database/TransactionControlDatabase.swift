public protocol TransactionControlDatabase: Database {
    func beginTransaction() -> EventLoopFuture<Void>
    func commitTransaction() -> EventLoopFuture<Void>
    func rollbackTransaction() -> EventLoopFuture<Void>
}
