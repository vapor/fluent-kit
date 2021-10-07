#if compiler(>=5.5) && canImport(_Concurrency)
import NIOCore

@available(macOS 12, iOS 15, watchOS 8, tvOS 15, *)
public protocol AsyncModelMiddleware: AnyModelMiddleware {
    associatedtype Model: FluentKit.Model
    
    func create(model: Model, on db: Database, next: AnyModelResponder) async throws
    func update(model: Model, on db: Database, next: AnyModelResponder) async throws
    func delete(model: Model, force: Bool, on db: Database, next: AnyModelResponder) async throws
    func softDelete(model: Model, on db: Database, next: AnyModelResponder) async throws
    func restore(model: Model, on db: Database, next: AnyModelResponder) async throws
}

@available(macOS 12, iOS 15, watchOS 8, tvOS 15, *)
extension AsyncModelMiddleware {
    public func handle(_ event: ModelEvent, _ model: AnyModel, on db: Database, chainingTo next: AnyModelResponder) -> EventLoopFuture<Void> {
        let promise = db.eventLoop.makePromise(of: Void.self)
        promise.completeWithTask {
            try await self.handle(model: modelType, on: db, next: next)
        }
        return promise.futureResult
    }
    
    public func handle(_ event: ModelEvent, _ model: AnyModel, on db: Database, chainingTo next: AnyModelResponder) async throws {
        guard let modelType = model as? Model else {
            return try await next.handle(event, model, on: db)
        }
        
        switch event {
        case .create:
            return try await self.create(model: modelType, on: db, next: next)
        case .update:
            return try await self.update(model: modelType, on: db, next: next)
        case .delete(let force):
            return try await self.delete(model: model, force: force, on: db, next: next)
        case .softDelete:
            return try await self.softDelete(model: modelType, on: db, next: next)
        case .restore:
            return try await self.restore(model: modelType, on: db, next: next)
        }
    }
    
    public func create(model: Model, on db: Database, next: AnyModelResponder) async throws {
        return try await next.create(model, on: db)
    }
    
    public func update(model: Model, on db: Database, next: AnyModelResponder) async throws {
        return try await next.update(model, on: db)
    }
    
    public func delete(model: Model, force: Bool, on db: Database, next: AnyModelResponder) async throws {
        return try await next.delete(model, force: force, on: db)
    }
    
    public func softDelete(model: Model, on db: Database, next: AnyModelResponder) async throws {
        return try await next.softDelete(model, on: db)
    }
    
    public func restore(model: Model, on db: Database, next: AnyModelResponder) async throws {
        return try await next.restore(model, on: db)
    }
}

@available(macOS 12, iOS 15, watchOS 8, tvOS 15, *)
extension AnyModelResponder {
    public func create(_ model: AnyModel, on db: Database) async throws {
        try await handle(.create, model, on: db)
    }
    
    public func update(_ model: AnyModel, on db: Database) async throws {
        try await handle(.update, model, on: db)
    }
    
    public func restore(_ model: AnyModel, on db: Database) async throws {
        try await handle(.restore, model, on: db)
    }
    
    public func softDelete(_ model: AnyModel, on db: Database) async throws {
        try await handle(.softDelete, model, on: db)
    }
    
    public func delete(_ model: AnyModel, force: Bool, on db: Database) async throws {
        try await handle(.delete(force), model, on: db)
    }
}


#endif
