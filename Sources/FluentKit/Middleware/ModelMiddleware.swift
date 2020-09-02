public enum ModelEvent {
    case create
    case update
    case delete(Bool)
    case restore
    @available(*, deprecated)
    case softDelete
}

public protocol ModelMiddleware: AnyModelMiddleware {
    associatedtype Model: FluentKit.Model

    func create(models: [Model], on db: Database, next: AnyModelResponder) -> EventLoopFuture<Void>
    func update(models: [Model], on db: Database, next: AnyModelResponder) -> EventLoopFuture<Void>
    func delete(models: [Model], force: Bool, on db: Database, next: AnyModelResponder) -> EventLoopFuture<Void>
    func restore(models: [Model], on db: Database, next: AnyModelResponder) -> EventLoopFuture<Void>

    @available(*, deprecated)
    func create(model: Model, on database: Database, next: AnyModelResponder) -> EventLoopFuture<Void>
    @available(*, deprecated)
    func update(model: Model, on database: Database, next: AnyModelResponder) -> EventLoopFuture<Void>
    @available(*, deprecated)
    func delete(model: Model, force: Bool, on database: Database, next: AnyModelResponder) -> EventLoopFuture<Void>
    @available(*, deprecated)
    func softDelete(model: Model, on database: Database, next: AnyModelResponder) -> EventLoopFuture<Void>
    @available(*, deprecated)
    func restore(model: Model, on database: Database, next: AnyModelResponder) -> EventLoopFuture<Void>
}

public protocol AnyModelMiddleware {
    func handle(
        _ event: ModelEvent,
        _ model: [AnyModel],
        on db: Database,
        chainingTo next: AnyModelResponder
    ) -> EventLoopFuture<Void>
}

extension ModelMiddleware {
    public func handle(
        _ event: ModelEvent,
        _ anyModels: [AnyModel],
        on database: Database,
        chainingTo next: AnyModelResponder
    ) -> EventLoopFuture<Void> {
        guard let models = anyModels as? [Model] else {
            return next.handle(event, anyModels, on: database)
        }

        switch event {
        case .create:
            return self.create(models: models, on: database, next: next)
        case .update:
            return self.update(models: models, on: database, next: next)
        case .delete(let force):
            return self.delete(models: models, force: force, on: database, next: next)
        case .restore:
            return self.restore(models: models, on: database, next: next)
        default:
            database.logger.warning("Ignoring deprecated model event: \(event)")
            return next.handle(event, models, on: database)
        }
    }
}

// Default implementations for required methods.
// These were added in a minor update so they cannot be properly required.
extension ModelMiddleware {
    @available(*, deprecated)
    public func create(models: [Model], on database: Database, next: AnyModelResponder) -> EventLoopFuture<Void> {
        switch models.count {
        case 1:
            return self.create(model: models[0], on: database, next: next)
        default:
            database.logger.warning("Ignoring batch model event. \(Self.self).\(#function) method not implemented. ")
            return next.create(models, on: database)
        }
    }

    @available(*, deprecated)
    public func update(models: [Model], on database: Database, next: AnyModelResponder) -> EventLoopFuture<Void> {
        switch models.count {
        case 1:
            return self.update(model: models[0], on: database, next: next)
        default:
            database.logger.warning("Ignoring batch model event. \(Self.self).\(#function) method not implemented. ")
            return next.create(models, on: database)
        }
    }

    @available(*, deprecated)
    public func delete(models: [Model], force: Bool, on database: Database, next: AnyModelResponder) -> EventLoopFuture<Void> {
        switch models.count {
        case 1:
            return self.delete(model: models[0], force: force, on: database, next: next)
        default:
            database.logger.warning("Ignoring batch model event. \(Self.self).\(#function) method not implemented. ")
            return next.create(models, on: database)
        }
    }

    @available(*, deprecated)
    public func restore(models: [Model], on database: Database, next: AnyModelResponder) -> EventLoopFuture<Void> {
        switch models.count {
        case 1:
            return self.restore(model: models[0], on: database, next: next)
        default:
            database.logger.warning("Ignoring batch model event. \(Self.self).\(#function) method not implemented. ")
            return next.create(models, on: database)
        }
    }
}

// Default implementations for deprecated methods.
// These are no longer required.
extension ModelMiddleware {
    @available(*, deprecated)
    public func create(model: Model, on database: Database, next: AnyModelResponder) -> EventLoopFuture<Void> {
        next.create(model, on: database)
    }

    @available(*, deprecated)
    public func update(model: Model, on database: Database, next: AnyModelResponder) -> EventLoopFuture<Void> {
        return next.update(model, on: database)
    }

    @available(*, deprecated)
    public func delete(model: Model, force: Bool, on database: Database, next: AnyModelResponder) -> EventLoopFuture<Void> {
        return next.delete(model, force: force, on: database)
    }

    @available(*, deprecated)
    public func softDelete(model: Model, on database: Database, next: AnyModelResponder) -> EventLoopFuture<Void> {
        return next.softDelete(model, on: database)
    }

    @available(*, deprecated)
    public func restore(model: Model, on database: Database, next: AnyModelResponder) -> EventLoopFuture<Void> {
        return next.restore(model, on: database)
    }
}

// MARK: Private

extension AnyModelMiddleware {
    func makeResponder(chainingTo responder: AnyModelResponder) -> AnyModelResponder {
        return ModelMiddlewareResponder(middleware: self, responder: responder)
    }
}

extension Array where Element == AnyModelMiddleware {
    internal func chainingTo<Model>(
        _ type: Model.Type,
        closure: @escaping (ModelEvent, [Model], Database) -> EventLoopFuture<Void>
    ) -> AnyModelResponder
        where Model: FluentKit.Model
    {
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
    
    func handle(
        _ event: ModelEvent,
        _ models: [AnyModel],
        on database: Database
    ) -> EventLoopFuture<Void> {
        self.middleware.handle(event, models, on: database, chainingTo: self.responder)
    }
}
