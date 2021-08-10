#if compiler(>=5.5)
 import _NIOConcurrency
#endif

public protocol AnyModelMiddleware {
    func handle(
        _ event: ModelEvent,
        _ model: AnyModel,
        on db: Database,
        chainingTo next: AnyModelResponder
    ) -> EventLoopFuture<Void>
}

public protocol ModelMiddleware: AnyModelMiddleware {
    associatedtype Model: FluentKit.Model
    
    func create(model: Model, on db: Database, next: AnyModelResponder) -> EventLoopFuture<Void>
    func update(model: Model, on db: Database, next: AnyModelResponder) -> EventLoopFuture<Void>
    func delete(model: Model, force: Bool, on db: Database, next: AnyModelResponder) -> EventLoopFuture<Void>
    func softDelete(model: Model, on db: Database, next: AnyModelResponder) -> EventLoopFuture<Void>
    func restore(model: Model, on db: Database, next: AnyModelResponder) -> EventLoopFuture<Void>

    #if compiler(>=5.5)
    @available(macOS 12, iOS 15, watchOS 8, tvOS 15, *)
    func create(model: Model, on db: Database, next: AnyModelResponder) async throws
    @available(macOS 12, iOS 15, watchOS 8, tvOS 15, *)
    func update(model: Model, on db: Database, next: AnyModelResponder) async throws
    @available(macOS 12, iOS 15, watchOS 8, tvOS 15, *)
    func delete(model: Model, force: Bool, on db: Database, next: AnyModelResponder) async throws
    @available(macOS 12, iOS 15, watchOS 8, tvOS 15, *)
    func softDelete(model: Model, on db: Database, next: AnyModelResponder) async throws
    @available(macOS 12, iOS 15, watchOS 8, tvOS 15, *)
    func restore(model: Model, on db: Database, next: AnyModelResponder) async throws
    #endif
}

extension ModelMiddleware {
    public func handle(_ event: ModelEvent, _ model: AnyModel, on db: Database, chainingTo next: AnyModelResponder) -> EventLoopFuture<Void> {
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
    
    #if compiler(>=5.5)
    @available(macOS 12, iOS 15, watchOS 8, tvOS 15, *)
    public func handle(_ event: ModelEvent, _ model: AnyModel, on db: Database, chainingTo next: AnyModelResponder) async throws {
        guard let modelType = model as? Model else {
            return try await next.handle(event, model, on: db).get()
        }
        
        switch event {
        case .create:
            return try await create(model: modelType, on: db, next: next)
        case .update:
            return try await update(model: modelType, on: db, next: next)
        case .delete(let force):
            return try await delete(model: modelType, force: force, on: db, next: next)
        case .softDelete:
            return try await softDelete(model: modelType, on: db, next: next)
        case .restore:
            return try await restore(model: modelType, on: db, next: next)
        }
    }
    #endif
    
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

extension AnyModelMiddleware {
    func makeResponder(chainingTo responder: AnyModelResponder) -> AnyModelResponder {
        return ModelMiddlewareResponder(middleware: self, responder: responder)
    }
}

extension Array where Element == AnyModelMiddleware {
    internal func chainingTo<Model>(_ type: Model.Type, closure: @escaping (ModelEvent, Model, Database) throws -> EventLoopFuture<Void>) -> AnyModelResponder where Model: FluentKit.Model {
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
    
    func handle(_ event: ModelEvent, _ model: AnyModel, on db: Database) -> EventLoopFuture<Void> {
        return self.middleware.handle(event, model, on: db, chainingTo: responder)
    }
}

public enum ModelEvent {
    case create
    case update
    case delete(Bool)
    case restore
    case softDelete
}
