import NIOCore

public protocol AsyncModelMiddleware: AnyModelMiddleware {
    associatedtype Model: FluentKit.Model
    
    func create(model: Model, on db: Database, next: AnyAsyncModelResponder) async throws
    func update(model: Model, on db: Database, next: AnyAsyncModelResponder) async throws
    func delete(model: Model, force: Bool, on db: Database, next: AnyAsyncModelResponder) async throws
    func softDelete(model: Model, on db: Database, next: AnyAsyncModelResponder) async throws
    func restore(model: Model, on db: Database, next: AnyAsyncModelResponder) async throws
}

extension AsyncModelMiddleware {
    public func handle(_ event: ModelEvent, _ model: AnyModel, on db: Database, chainingTo next: AnyModelResponder) -> EventLoopFuture<Void> {
        let promise = db.eventLoop.makePromise(of: Void.self)
        promise.completeWithTask {
            guard let modelType = model as? Model else {
                try await next.handle(event, model, on: db).get()
                return
            }

            let responder = AsyncBasicModelResponder { responderEvent, responderModel, responderDB in
                return try await next.handle(responderEvent, responderModel, on: responderDB).get()
            }

            switch event {
            case .create:
                try await self.create(model: modelType, on: db, next: responder)
            case .update:
                try await self.update(model: modelType, on: db, next: responder)
            case .delete(let force):
                try await self.delete(model: modelType, force: force, on: db, next: responder)
            case .softDelete:
                try await self.softDelete(model: modelType, on: db, next: responder)
            case .restore:
                try await self.restore(model: modelType, on: db, next: responder)
            }
        }
        return promise.futureResult
    }
    
    public func create(model: Model, on db: Database, next: AnyAsyncModelResponder) async throws {
        try await next.create(model, on: db)
    }
    
    public func update(model: Model, on db: Database, next: AnyAsyncModelResponder) async throws {
        try await next.update(model, on: db)
    }
    
    public func delete(model: Model, force: Bool, on db: Database, next: AnyAsyncModelResponder) async throws {
        try await next.delete(model, force: force, on: db)
    }
    
    public func softDelete(model: Model, on db: Database, next: AnyAsyncModelResponder) async throws {
        try await next.softDelete(model, on: db)
    }
    
    public func restore(model: Model, on db: Database, next: AnyAsyncModelResponder) async throws {
        try await next.restore(model, on: db)
    }
}
