import NIOCore

public protocol AnyModelMiddleware: Sendable {
    func handle(
        _ event: ModelEvent,
        _ model: any AnyModel,
        on db: any Database,
        chainingTo next: any AnyModelResponder
    ) async throws
}

public protocol ModelMiddleware: AnyModelMiddleware {
    associatedtype Model: FluentKit.Model

    func create(model: Model, on db: any Database, next: any AnyModelResponder) async throws
    func update(model: Model, on db: any Database, next: any AnyModelResponder) async throws
    func delete(model: Model, on db: any Database, next: any AnyModelResponder) async throws
}

extension ModelMiddleware {
    public func handle(
        _ event: ModelEvent,
        _ model: any AnyModel,
        on db: any Database,
        chainingTo next: any AnyModelResponder
    ) async throws {
        guard let modelType = model as? Model else {
            return try await next.handle(event, model, on: db)
        }

        let responder = BasicModelResponder<Model> { responderEvent, responderModel, responderDB in
            try await next.handle(responderEvent, responderModel, on: responderDB)
        }

        switch event {
        case .create:
            try await self.create(model: modelType, on: db, next: responder)
        case .update:
            try await self.update(model: modelType, on: db, next: responder)
        case .delete:
            try await self.delete(model: modelType, on: db, next: responder)
        }
    }

    public func create(model: Model, on db: any Database, next: any AnyModelResponder) async throws {
        try await next.create(model, on: db)
    }

    public func update(model: Model, on db: any Database, next: any AnyModelResponder) async throws {
        try await next.update(model, on: db)
    }

    public func delete(model: Model, on db: any Database, next: any AnyModelResponder) async throws {
        try await next.delete(model, on: db)
    }
}

extension AnyModelMiddleware {
    func makeResponder(chainingTo responder: any AnyModelResponder) -> any AnyModelResponder {
        ModelMiddlewareResponder(middleware: self, responder: responder)
    }
}

extension Array where Element == any AnyModelMiddleware {
    func chainingTo<Model>(
        _ type: Model.Type,
        closure: @escaping @Sendable (ModelEvent, Model, any Database) async throws -> ()
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
    
    func handle(_ event: ModelEvent, _ model: any AnyModel, on db: any Database) async throws {
        try await self.middleware.handle(event, model, on: db, chainingTo: responder)
    }
}

public enum ModelEvent: Sendable {
    case create
    case update
    case delete
}
