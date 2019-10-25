public protocol AnyModelResponder {
    func handle(event: ModelEvent, model: AnyModel, on db: Database) -> EventLoopFuture<Void>
}

public struct BasicModelResponder: AnyModelResponder {
    private let _handle: (ModelEvent, AnyModel, Database) throws -> EventLoopFuture<Void>
    
    public func handle(event: ModelEvent, model: AnyModel, on db: Database) -> EventLoopFuture<Void> {
        do {
            return try _handle(event, model, db)
        } catch {
            return db.eventLoop.makeFailedFuture(error)
        }
    }
    
    init(handle: @escaping (ModelEvent, AnyModel, Database) throws -> EventLoopFuture<Void>) {
        self._handle = handle
    }
}
