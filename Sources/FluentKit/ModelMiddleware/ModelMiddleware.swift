public protocol AnyModelMiddleware {
    func handle(event: ModelEvent, model: AnyModel, on db: Database, chainingTo next: AnyModelResponder) -> EventLoopFuture<Void>
}

public protocol ModelMiddleware: AnyModelMiddleware {
    associatedtype Model: FluentKit.Model
    
    func create(model: Model, on db: Database, next: AnyModelResponder) -> EventLoopFuture<Void>
    func update(model: Model, on db: Database, next: AnyModelResponder) -> EventLoopFuture<Void>
    func delete(model: Model, on db: Database, next: AnyModelResponder) -> EventLoopFuture<Void>
    func softDelete(model: Model, on db: Database, next: AnyModelResponder) -> EventLoopFuture<Void>
    func restore(model: Model, on db: Database, next: AnyModelResponder) -> EventLoopFuture<Void>
}

extension ModelMiddleware {
    public func handle(event: ModelEvent, model: AnyModel, on db: Database, chainingTo next: AnyModelResponder) -> EventLoopFuture<Void> {
        guard let modelType = model as? Model else {
            return next.handle(event: event, model: model, on: db)
        }
        
        switch event {
        case .create:
            return self.create(model: modelType, on: db, next: next)
        case .update:
            return self.update(model: modelType, on: db, next: next)
        case .delete:
            return self.delete(model: modelType, on: db, next: next)
        case .softDelete:
            return self.softDelete(model: modelType, on: db, next: next)
        case .restore:
            return self.restore(model: modelType, on: db, next: next)
        }
    }
    
    public func create(model: Model, on db: Database, next: AnyModelResponder) -> EventLoopFuture<Void> {
        return next.handle(event: .create, model: model, on: db)
    }
    
    public func update(model: Model, on db: Database, next: AnyModelResponder) -> EventLoopFuture<Void> {
        return next.handle(event: .update, model: model, on: db)
    }
    
    public func delete(model: Model, on db: Database, next: AnyModelResponder) -> EventLoopFuture<Void> {
        return next.handle(event: .delete, model: model, on: db)
    }
    
    public func softDelete(model: Model, on db: Database, next: AnyModelResponder) -> EventLoopFuture<Void> {
        return next.handle(event: .softDelete, model: model, on: db)
    }
    
    public func restore(model: Model, on db: Database, next: AnyModelResponder) -> EventLoopFuture<Void> {
        return next.handle(event: .restore, model: model, on: db)
    }
}

extension AnyModelMiddleware {
    func makeResponder(chainingTo responder: AnyModelResponder) -> AnyModelResponder {
        return ModelMiddlewareResponder(middleware: self, responder: responder)
    }
}

extension Array where Element == AnyModelMiddleware {
    internal func chainingTo(closure: @escaping BasicModelResponderClosure) -> AnyModelResponder {
        var responder: AnyModelResponder = BasicModelResponder(handle: closure)
        for middleware in reversed() {
            responder = middleware.makeResponder(chainingTo: responder)
        }
        return responder
    }
}

private struct ModelMiddlewareResponder: AnyModelResponder {
    var middleware: AnyModelMiddleware
    var responder: AnyModelResponder
    
    func handle(event: ModelEvent, model: AnyModel, on db: Database) -> EventLoopFuture<Void> {
        return self.middleware.handle(event: event, model: model, on: db, chainingTo: responder)
    }
}

public enum ModelEvent {
    case create
    case update
    case delete
    case restore
    case softDelete
}
