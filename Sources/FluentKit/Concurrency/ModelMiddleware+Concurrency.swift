#if compiler(>=5.5) && $AsyncAwait
import _NIOConcurrency

@available(macOS 9999, iOS 9999, watchOS 9999, tvOS 9999, *)
public extension ModelMiddleware {
    func create(model: Model, on db: Database, next: AnyModelResponder) async throws {
        try await self.create(model: model, on: db, next: next).get()
    }
    
    func update(model: Model, on db: Database, next: AnyModelResponder) async throws {
        try await self.update(model: model, on: db, next: next).get()
    }
    
    func delete(model: Model, force: Bool, on db: Database, next: AnyModelResponder) async throws {
        try await self.delete(model: model, force: force, on: db, next: next).get()
    }
    
    func softDelete(model: Model, on db: Database, next: AnyModelResponder) async throws {
        try await self.softDelete(model: model, on: db, next: next).get()
    }
    
    func restore(model: Model, on db: Database, next: AnyModelResponder) async throws {
        try await self.restore(model: model, on: db, next: next).get()
    }
}

#endif
