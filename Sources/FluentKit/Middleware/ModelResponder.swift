public protocol AnyModelResponder: Sendable {
    func handle(
        _ event: ModelEvent,
        _ model: any AnyModel,
        on db: any Database
    ) async throws
}

extension AnyModelResponder {
    public func create(_ model: any AnyModel, on db: any Database) async throws {
        try await self.handle(.create, model, on: db)
    }
    
    public func update(_ model: any AnyModel, on db: any Database) async throws {
        try await self.handle(.update, model, on: db)
    }
    
    public func delete(_ model: any AnyModel, on db: any Database) async throws {
        try await self.handle(.delete, model, on: db)
    }
}

struct BasicModelResponder<Model>: AnyModelResponder where Model: FluentKit.Model {
    private let _handle: @Sendable (ModelEvent, Model, any Database) async throws -> ()

    func handle(_ event: ModelEvent, _ model: any AnyModel, on db: any Database) async throws {
        guard let modelType = model as? Model else {
            fatalError("Could not convert type AnyModel to \(Model.self)")
        }

        return try await self._handle(event, modelType, db)
    }
    
    init(handle: @escaping @Sendable (ModelEvent, Model, any Database) async throws -> ()) {
        self._handle = handle
    }
}
