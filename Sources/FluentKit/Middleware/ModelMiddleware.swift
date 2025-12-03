import NIOCore

public protocol AnyModelMiddleware: Sendable {
    func handle(
        _ event: ModelEvent,
        _ model: any AnyModel,
        on db: any Database,
        chainingTo next: any AnyModelResponder
    ) -> EventLoopFuture<Void>
}

public protocol ModelMiddleware: AnyModelMiddleware {
    associatedtype Model: FluentKit.Model

    func create(model: Model, on db: any Database, next: any AnyModelResponder) -> EventLoopFuture<Void>
    func update(model: Model, on db: any Database, next: any AnyModelResponder) -> EventLoopFuture<Void>
    func delete(model: Model, force: Bool, on db: any Database, next: any AnyModelResponder) -> EventLoopFuture<Void>
    func softDelete(model: Model, on db: any Database, next: any AnyModelResponder) -> EventLoopFuture<Void>
    func restore(model: Model, on db: any Database, next: any AnyModelResponder) -> EventLoopFuture<Void>
}

extension ModelMiddleware {
    public func handle(_ event: ModelEvent, _ model: any AnyModel, on db: any Database, chainingTo next: any AnyModelResponder)
        -> EventLoopFuture<Void>
    {
        guard let modelType = model as? Model else {
            return next.handle(event, model, on: db)
        }

        switch event {
        case .create:
            return create(model: modelType, on: db, next: next)
        case .update:
            return update(model: modelType, on: db, next: next)
        case .delete(let force):
            return delete(model: modelType, force: force, on: db, next: next)
        case .softDelete:
            return softDelete(model: modelType, on: db, next: next)
        case .restore:
            return restore(model: modelType, on: db, next: next)
        }
    }

    public func create(model: Model, on db: any Database, next: any AnyModelResponder) -> EventLoopFuture<Void> {
        next.create(model, on: db)
    }

    public func update(model: Model, on db: any Database, next: any AnyModelResponder) -> EventLoopFuture<Void> {
        next.update(model, on: db)
    }

    public func delete(model: Model, force: Bool, on db: any Database, next: any AnyModelResponder) -> EventLoopFuture<Void> {
        next.delete(model, force: force, on: db)
    }

    public func softDelete(model: Model, on db: any Database, next: any AnyModelResponder) -> EventLoopFuture<Void> {
        next.softDelete(model, on: db)
    }

    public func restore(model: Model, on db: any Database, next: any AnyModelResponder) -> EventLoopFuture<Void> {
        next.restore(model, on: db)
    }
}

extension AnyModelMiddleware {
    func makeResponder(chainingTo responder: any AnyModelResponder) -> any AnyModelResponder {
        ModelMiddlewareResponder(middleware: self, responder: responder)
    }
}

extension Array where Element == any AnyModelMiddleware {
    internal func chainingTo<Model>(
        _ type: Model.Type,
        closure: @escaping @Sendable (ModelEvent, Model, any Database) throws -> EventLoopFuture<Void>
    ) -> any AnyModelResponder where Model: FluentKit.Model {
        var responder: any AnyModelResponder = BasicModelResponder(handle: closure)
        for middleware in reversed() {
            responder = middleware.makeResponder(chainingTo: responder)
        }
        return responder
    }
}

private struct ModelMiddlewareResponder: AnyModelResponder {
    var middleware: any AnyModelMiddleware
    var responder: any AnyModelResponder

    func handle(_ event: ModelEvent, _ model: any AnyModel, on db: any Database) -> EventLoopFuture<Void> {
        self.middleware.handle(event, model, on: db, chainingTo: responder)
    }
}

public enum ModelEvent: Sendable {
    case create
    case update
    case delete(Bool)
    case restore
    case softDelete
}
