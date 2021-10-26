#if compiler(>=5.5) && canImport(_Concurrency)
import NIOCore

@available(macOS 12, iOS 15, watchOS 8, tvOS 15, *)
public protocol AsyncModelMiddleware: AnyModelMiddleware {
    associatedtype Model: FluentKit.Model
    
    func create(model: Model, on db: Database, next: AnyAsyncModelResponder) async throws
    func update(model: Model, on db: Database, next: AnyAsyncModelResponder) async throws
    func delete(model: Model, force: Bool, on db: Database, next: AnyAsyncModelResponder) async throws
    func softDelete(model: Model, on db: Database, next: AnyAsyncModelResponder) async throws
    func restore(model: Model, on db: Database, next: AnyAsyncModelResponder) async throws
}

@available(macOS 12, iOS 15, watchOS 8, tvOS 15, *)
extension AsyncModelMiddleware {
    public func handle(_ event: ModelEvent, _ model: AnyModel, on db: Database, chainingTo next: AnyAsyncModelResponder) async throws {
        guard let modelType = model as? Model else {
            try await next.handle(event, model, on: db)
            return
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

#endif
