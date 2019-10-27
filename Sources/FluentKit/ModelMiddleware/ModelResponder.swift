public protocol AnyModelResponder {
    func handle(_ event: ModelEvent, _ model: AnyModel, on db: Database) -> EventLoopFuture<Void>
}

internal typealias BasicModelResponderClosure = (ModelEvent, AnyModel, Database) throws -> EventLoopFuture<Void>

internal struct BasicModelResponder: AnyModelResponder {
    private let _handle: BasicModelResponderClosure
    
    public func handle(_ event: ModelEvent, _ model: AnyModel, on db: Database) -> EventLoopFuture<Void> {
        do {
            return try _handle(event, model, db)
        } catch {
            return db.eventLoop.makeFailedFuture(error)
        }
    }
    
    init(handle: @escaping BasicModelResponderClosure) {
        self._handle = handle
    }
}
