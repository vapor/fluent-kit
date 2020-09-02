public protocol AnyModelResponder {
    func handle(
        _ event: ModelEvent,
        _ model: [AnyModel],
        on database: Database
    ) -> EventLoopFuture<Void>
}

extension AnyModelResponder {
    public func create(_ model: AnyModel, on database: Database) -> EventLoopFuture<Void> {
        self.handle(.create, [model], on: database)
    }
    
    public func update(_ model: AnyModel, on database: Database) -> EventLoopFuture<Void> {
        self.handle(.update, [model], on: database)
    }
    
    public func restore(_ model: AnyModel, on database: Database) -> EventLoopFuture<Void> {
        self.handle(.restore, [model], on: database)
    }
    
    public func softDelete(_ model: AnyModel, on database: Database) -> EventLoopFuture<Void> {
        self.handle(.softDelete, [model], on: database)
    }
    
    public func delete(_ model: AnyModel, force: Bool, on database: Database) -> EventLoopFuture<Void> {
        return handle(.delete(force), [model], on: database)
    }

    public func create(_ models: [AnyModel], on database: Database) -> EventLoopFuture<Void> {
        self.handle(.create, models, on: database)
    }

    public func update(_ models: [AnyModel], on database: Database) -> EventLoopFuture<Void> {
        self.handle(.update, models, on: database)
    }

    public func restore(_ models: [AnyModel], on database: Database) -> EventLoopFuture<Void> {
        self.handle(.restore, models, on: database)
    }

    public func softDelete(_ models: [AnyModel], on database: Database) -> EventLoopFuture<Void> {
        self.handle(.softDelete, models, on: database)
    }

    public func delete(_ models: [AnyModel], force: Bool, on database: Database) -> EventLoopFuture<Void> {
        return self.handle(.delete(force), models, on: database)
    }
}

internal struct BasicModelResponder<Model>: AnyModelResponder
    where Model: FluentKit.Model
{
    private let _handle: (ModelEvent, [Model], Database) -> EventLoopFuture<Void>
    
    internal func handle(_ event: ModelEvent, _ anyModels: [AnyModel], on db: Database) -> EventLoopFuture<Void> {
        guard let models = anyModels as? [Model] else {
            fatalError("Could not convert type AnyModel to \(Model.self)")
        }
        return self._handle(event, models, db)
    }
    
    init(handle: @escaping (ModelEvent, [Model], Database) -> EventLoopFuture<Void>) {
        self._handle = handle
    }
}

