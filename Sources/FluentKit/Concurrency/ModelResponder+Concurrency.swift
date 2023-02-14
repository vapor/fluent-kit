import NIOCore

public protocol AnyAsyncModelResponder: AnyModelResponder {
    func handle(
        _ event: ModelEvent,
        _ model: AnyModel,
        on db: Database
    ) async throws
}

extension AnyAsyncModelResponder {
    func handle(_ event: ModelEvent, _ model: AnyModel, on db: Database) -> EventLoopFuture<Void> {
        let promise = db.eventLoop.makePromise(of: Void.self)
        promise.completeWithTask {
            try await self.handle(event, model, on: db)
        }
        return promise.futureResult
    }
}

extension AnyAsyncModelResponder {
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

internal struct AsyncBasicModelResponder: AnyAsyncModelResponder {
    private let _handle: (ModelEvent, AnyModel, Database) async throws -> Void

    internal func handle(_ event: ModelEvent, _ model: AnyModel, on db: Database) async throws {
        return try await _handle(event, model, db)
    }

    init(handle: @escaping (ModelEvent, AnyModel, Database) async throws -> Void) {
        self._handle = handle
    }
}
