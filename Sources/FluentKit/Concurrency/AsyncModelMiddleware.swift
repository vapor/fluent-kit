import NIOCore

public protocol AsyncModelMiddleware: AnyModelMiddleware {
    associatedtype Model: FluentKit.Model
    
    func create(model: Model, on db: any Database, next: any AnyAsyncModelResponder) async throws
    func update(model: Model, on db: any Database, next: any AnyAsyncModelResponder) async throws
    func delete(model: Model, force: Bool, on db: any Database, next: any AnyAsyncModelResponder) async throws
    func softDelete(model: Model, on db: any Database, next: any AnyAsyncModelResponder) async throws
    func restore(model: Model, on db: any Database, next: any AnyAsyncModelResponder) async throws
}

extension AsyncModelMiddleware {
    func handle(
        _ event: ModelEvent,
        _ model: any AnyModel,
        on db: any Database,
        chainingTo next: any AnyAsyncModelResponder
    ) async throws {
        guard let modelType = (model as? Model) else {
            return try await next.handle(event, model, on: db)
        }

        switch event {
        case .create:
            try await self.create(model: modelType, on: db, next: next)
        case .update:
            try await self.update(model: modelType, on: db, next: next)
        case .delete(let force):
            try await self.delete(model: modelType, force: force, on: db, next: next)
        case .softDelete:
            try await self.softDelete(model: modelType, on: db, next: next)
        case .restore:
            try await self.restore(model: modelType, on: db, next: next)
        }
    }

    public func handle(
        _ event: ModelEvent,
        _ model: any AnyModel,
        on db: any Database,
        chainingTo next: any AnyModelResponder
    ) -> EventLoopFuture<Void> { 
        db.eventLoop.makeFutureWithTask {
            let responder = AnyAsyncBasicModelResponder { responderModel, responderEvent, responderDB in 
                if let next = (next as? any AnyAsyncModelResponder) {
                    try await next.handle(responderModel, responderEvent, on: responderDB)
                } else {
                    try await next.handle(responderModel, responderEvent, on: responderDB).get()
                }
            }
            try await self.handle(event, model, on: db, chainingTo: responder)
        }
    }
    
    public func create(model: Model, on db: any Database, next: any AnyAsyncModelResponder) async throws {
        try await next.create(model, on: db)
    }
    
    public func update(model: Model, on db: any Database, next: any AnyAsyncModelResponder) async throws {
        try await next.update(model, on: db)
    }
    
    public func delete(model: Model, force: Bool, on db: any Database, next: any AnyAsyncModelResponder) async throws {
        try await next.delete(model, force: force, on: db)
    }
    
    public func softDelete(model: Model, on db: any Database, next: any AnyAsyncModelResponder) async throws {
        try await next.softDelete(model, on: db)
    }
    
    public func restore(model: Model, on db: any Database, next: any AnyAsyncModelResponder) async throws {
        try await next.restore(model, on: db)
    }
}
