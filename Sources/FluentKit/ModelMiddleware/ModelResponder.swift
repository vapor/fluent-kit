public protocol AnyModelResponder {
    func handle(_ event: ModelEvent, _ model: AnyModel, on db: Database) -> EventLoopFuture<Void>
}

internal struct ModelResponder<Model>: AnyModelResponder where Model: FluentKit.Model {
    private let _handle: (ModelEvent, Model, Database) throws -> EventLoopFuture<Void>
    
    func handle(_ event: ModelEvent, _ model: AnyModel, on db: Database) -> EventLoopFuture<Void> {
        guard let modelType = model as? Model else {
            fatalError("Could not convert type AnyModel to \(Model.self)")
        }
        
        do {
            return try _handle(event, modelType, db)
        } catch {
            return db.eventLoop.makeFailedFuture(error)
        }
    }
    
    init(handle: @escaping (ModelEvent, Model, Database) throws -> EventLoopFuture<Void>) {
        self._handle = handle
    }
}

