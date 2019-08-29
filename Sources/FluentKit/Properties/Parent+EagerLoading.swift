// MARK: - Subquery

private protocol SubqueryLoader: EagerLoadRequest {
    associatedtype ParentModel: ModelIdentifiable
    associatedtype Model: FluentKit.Model

    var loader: Parent<ParentModel>.SubqueryEagerLoad { get }

    func map(model: Model) -> ParentModel
}

extension SubqueryLoader {
    var description: String { "\(self.key): \(self.loader.storage)" }
    var key: String { self.loader.key }

    func prepare(query: inout DatabaseQuery) { }

    func run(models: [AnyModel], on database: Database) -> EventLoopFuture<Void> {
        let ids: [Model.IDValue] = models
            .map { try! $0.anyID.cachedOutput!.decode(field: self.key, as: Model.IDValue.self) }

        let uniqueIDs = Array(Set(ids))
        return Model.query(on: database)
            .filter(Model.key(for: \._$id), in: uniqueIDs)
            .all()
            .map { self.loader.storage = $0.map(self.map(model:)) }
    }
}

extension Parent where To: ModelIdentifiable {
    final class SubqueryEagerLoad: EagerLoadRequest {
        let key: String
        var storage: [To]
        private var request: EagerLoadRequest!

        var description: String { self.request.description }

        private init(key: String, request generator: (Parent<To>.SubqueryEagerLoad) -> EagerLoadRequest) {
            self.storage = []
            self.key = key
            self.request = nil

            self.request = generator(self)
        }

        func prepare(query: inout DatabaseQuery) {
            self.request.prepare(query: &query)
        }

        func run(models: [AnyModel], on database: Database) -> EventLoopFuture<Void> {
            self.request.run(models: models, on: database)
        }

        func get(id: To.IDValue) throws -> To? {
            return self.storage.first(where: { parent in parent.id == id })
        }
    }
}

extension Parent.SubqueryEagerLoad where Parent.To: Model {
    internal convenience init(key: String) {
        self.init(key: key, request: Required.init(loader:))
    }

    private final class Required: SubqueryLoader {
        typealias ParentModel = Parent.To
        typealias Model = Parent.To

        let loader: Parent.SubqueryEagerLoad

        fileprivate init(loader: Parent.SubqueryEagerLoad) {
            self.loader = loader
        }

        func map(model: Model) -> ParentModel { model }
    }
}

extension Parent.SubqueryEagerLoad where Parent.To: OptionalType, Parent.To.Wrapped: Model {
    internal convenience init(key: String) {
        self.init(key: key, request: Optional.init(loader:))
    }

    private final class Optional: SubqueryLoader {
        typealias ParentModel = Parent.To
        typealias Model = Parent.To.Wrapped

        let loader: Parent.SubqueryEagerLoad

        fileprivate init(loader: Parent.SubqueryEagerLoad) {
            self.loader = loader
        }

        func map(model: T.Wrapped) -> T { model as! T }
    }
}

// MARK: - Join

extension Parent where To: ModelIdentifiable {
    final class JoinEagerLoad: EagerLoadRequest {
        let key: String
        var storage: [To]
        private var request: EagerLoadRequest!

        var description: String { self.request.description }

        private init(key: String, request generator: (Parent<To>.JoinEagerLoad) -> EagerLoadRequest) {
            self.storage = []
            self.key = key
            self.request = nil

            self.request = generator(self)
        }

        func prepare(query: inout DatabaseQuery) {
            self.request.prepare(query: &query)
        }

        func run(models: [AnyModel], on database: Database) -> EventLoopFuture<Void> {
            return self.request.run(models: models, on: database)
        }

        func get(id: To.IDValue) throws -> To? {
            return self.storage.first(where: { parent in parent.id == id })
        }
    }
}

private protocol JoinLoader: EagerLoadRequest {
    associatedtype ParentModel: ModelIdentifiable
    associatedtype Model: FluentKit.Model

    var loader: Parent<ParentModel>.JoinEagerLoad { get }

    func map(model: Model) -> ParentModel
}

extension JoinLoader {
    var description: String { "\(self.key): \(self.loader.storage)" }
    var key: String { self.loader.key }

    func prepare(query: inout DatabaseQuery) {
        // we can assume query.schema since eager loading
        // is only allowed on the base schema
        query.joins.append(.model(
            foreign: .field(path: [Model.key(for: \._$id)], schema: Model.schema, alias: nil),
            local: .field(path: [self.key], schema: query.schema, alias: nil),
            method: .inner
        ))
        query.fields += Model().fields.map { (_, field) in
            return .field(
                path: [field.key],
                schema: Model.schema,
                alias: Model.schema + "_" + field.key
            )
        }
    }

    func run(models: [AnyModel], on database: Database) -> EventLoopFuture<Void> {
        do {
            self.loader.storage = try models.map { child in
                return try self.map(model: child.joined(Model.self))
            }
            return database.eventLoop.makeSucceededFuture(())
        } catch {
            return database.eventLoop.makeFailedFuture(error)
        }
    }
}

extension Parent.JoinEagerLoad where Parent.To: Model {
    internal convenience init(key: String) {
        self.init(key: key, request: Required.init(loader:))
    }

    private final class Required: JoinLoader {
        typealias ParentModel = Parent.To
        typealias Model = Parent.To

        let loader: Parent.JoinEagerLoad

        fileprivate init(loader: Parent.JoinEagerLoad) {
            self.loader = loader
        }

        func map(model: Model) -> ParentModel { model }
    }
}

extension Parent.JoinEagerLoad where Parent.To: OptionalType, Parent.To.Wrapped: Model {
    internal convenience init(key: String) {
        self.init(key: key, request: Optional.init(loader:))
    }

    private final class Optional: JoinLoader {
        typealias ParentModel = Parent.To
        typealias Model = Parent.To.Wrapped

        let loader: Parent.JoinEagerLoad

        fileprivate init(loader: Parent.JoinEagerLoad) {
            self.loader = loader
        }

        func map(model: T.Wrapped) -> T { model as! T }
    }
}
