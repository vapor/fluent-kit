public protocol AnyModelMiddleware {
    func handle(
        _ event: ModelEvent,
        _ model: [AnyModel],
        on db: Database,
        chainingTo next: AnyModelResponder
    ) -> EventLoopFuture<Void>
}

public protocol ModelMiddleware: AnyModelMiddleware {
    associatedtype Model: FluentKit.Model
    
    func create(model: Model, on database: Database, next: AnyModelResponder) -> EventLoopFuture<Void>
    func update(model: Model, on database: Database, next: AnyModelResponder) -> EventLoopFuture<Void>
    func delete(model: Model, force: Bool, on database: Database, next: AnyModelResponder) -> EventLoopFuture<Void>
    func softDelete(model: Model, on database: Database, next: AnyModelResponder) -> EventLoopFuture<Void>
    func restore(model: Model, on database: Database, next: AnyModelResponder) -> EventLoopFuture<Void>

    // batch
    func batchCreate(models: [Model], on db: Database, next: AnyModelResponder) -> EventLoopFuture<Void>
}

extension ModelMiddleware {
    @available(*, deprecated, message: "Backward compatability")
    public func batchCreate(models: [Model], on database: Database, next: AnyModelResponder) -> EventLoopFuture<Void> {
        next.create(models, on: database)
    }
}

extension ModelMiddleware {
    public func handle(
        _ event: ModelEvent,
        _ anyModels: [AnyModel],
        on database: Database,
        chainingTo next: AnyModelResponder
    ) -> EventLoopFuture<Void> {
        guard let models = anyModels as? [Model] else {
            return next.handle(event, anyModels, on: database)
        }

        switch models.count {
        case 1:
            switch event {
            case .create:
                return self.create(model: models[0], on: database, next: next)
            case .update:
                return self.update(model: models[0], on: database, next: next)
            case .delete(let force):
                return self.delete(model: models[0], force: force, on: database, next: next)
            case .softDelete:
                return self.softDelete(model: models[0], on: database, next: next)
            case .restore:
                return self.restore(model: models[0], on: database, next: next)
            }
        default:
            switch event {
            case .create:
                return self.batchCreate(models: models, on: database, next: next)
            default:
                fatalError("Unsupported batch.")
            }
        }
    }
    
    public func create(model: Model, on db: Database, next: AnyModelResponder) -> EventLoopFuture<Void> {
        return next.create(model, on: db)
    }
    
    public func update(model: Model, on db: Database, next: AnyModelResponder) -> EventLoopFuture<Void> {
        return next.update(model, on: db)
    }
    
    public func delete(model: Model, force: Bool, on db: Database, next: AnyModelResponder) -> EventLoopFuture<Void> {
        return next.delete(model, force: force, on: db)
    }
    
    public func softDelete(model: Model, on db: Database, next: AnyModelResponder) -> EventLoopFuture<Void> {
        return next.softDelete(model, on: db)
    }
    
    public func restore(model: Model, on db: Database, next: AnyModelResponder) -> EventLoopFuture<Void> {
        return next.restore(model, on: db)
    }
}

public enum ModelEvent {
    case create
    case update
    case delete(Bool)
    case restore
    case softDelete
}

extension AnyModelMiddleware {
    func makeResponder(chainingTo responder: AnyModelResponder) -> AnyModelResponder {
        return ModelMiddlewareResponder(middleware: self, responder: responder)
    }
}

extension Array where Element == AnyModelMiddleware {
    internal func chainingTo<Model>(
        _ type: Model.Type,
        closure: @escaping (ModelEvent, [Model], Database) -> EventLoopFuture<Void>
    ) -> AnyModelResponder
        where Model: FluentKit.Model
    {
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
    
    func handle(
        _ event: ModelEvent,
        _ models: [AnyModel],
        on database: Database
    ) -> EventLoopFuture<Void> {
        self.middleware.handle(event, models, on: database, chainingTo: self.responder)
    }
}
