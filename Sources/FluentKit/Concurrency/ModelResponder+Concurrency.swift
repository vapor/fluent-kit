import NIOCore

public protocol AnyAsyncModelResponder: AnyModelResponder {
    func handle(
        _ event: ModelEvent,
        _ model: any AnyModel,
        on db: any Database
    ) async throws
}

extension AnyAsyncModelResponder {
    func handle(_ event: ModelEvent, _ model: any AnyModel, on db: any Database) -> EventLoopFuture<Void> {
        let model = UnsafeTransfer(wrappedValue: model)
        
        return db.eventLoop.makeFutureWithTask {
            try await self.handle(event, model.wrappedValue, on: db)
        }
    }
}

extension AnyAsyncModelResponder {
    public func create(_ model: any AnyModel, on db: any Database) async throws {
        try await handle(.create, model, on: db)
    }
    
    public func update(_ model: any AnyModel, on db: any Database) async throws {
        try await handle(.update, model, on: db)
    }
    
    public func restore(_ model: any AnyModel, on db: any Database) async throws {
        try await handle(.restore, model, on: db)
    }
    
    public func softDelete(_ model: any AnyModel, on db: any Database) async throws {
        try await handle(.softDelete, model, on: db)
    }
    
    public func delete(_ model: any AnyModel, force: Bool, on db: any Database) async throws {
        try await handle(.delete(force), model, on: db)
    }
}

internal struct AsyncBasicModelResponder: AnyAsyncModelResponder {
    private let _handle: @Sendable (ModelEvent, any AnyModel, any Database) async throws -> Void

    internal func handle(_ event: ModelEvent, _ model: any AnyModel, on db: any Database) async throws {
        try await _handle(event, model, db)
    }

    init(handle: @escaping @Sendable (ModelEvent, any AnyModel, any Database) async throws -> Void) {
        self._handle = handle
    }
}
