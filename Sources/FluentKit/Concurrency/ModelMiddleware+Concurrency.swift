#if compiler(>=5.5) && canImport(_Concurrency)
import NIOCore

@available(macOS 12, iOS 15, watchOS 8, tvOS 15, *)
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
