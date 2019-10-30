extension Parent: AnyEagerLoadable {
    var eagerLoadKey: String {
        return "p:" + self.$id.key
    }

    var eagerLoadValueDescription: CustomStringConvertible? {
        return self.eagerLoadedValue
    }

    func eagerLoad(from eagerLoads: EagerLoads) throws {
        guard let request = eagerLoads.requests[self.eagerLoadKey] else {
            return
        }

        if let subquery = request as? ParentSubqueryEagerLoad<To> {
            self.eagerLoadedValue = try subquery.get(id: id)
        } else {
            fatalError("unsupported eagerload request: \(request)")
        }
    }
}


// MARK: - Eager Loadable

extension Parent where To: Model {
    internal func subqueryLoader(for key: String) -> EagerLoadRequest {
        return ParentSubqueryEagerLoad<To>(key: key)
    }
}

extension Parent where To: OptionalType, To.Wrapped: Model {
    internal func subqueryLoader(for key: String) -> EagerLoadRequest {
        return ParentSubqueryEagerLoad<To>(key: key)
    }
}

extension Parent {
    internal func subqueryLoader(for key: String) -> EagerLoadRequest {
        fatalError("""
        You created a parent with a type that is neither a Model or Optional<Model>. \
        You deserved to crash.
        """)
    }
}

extension Parent: EagerLoadable {
    public func eagerLoad<Model>(to builder: QueryBuilder<Model>) where Model: FluentKit.Model {
        builder.eagerLoads.requests[self.eagerLoadKey] = self.subqueryLoader(for: self.$id.key)
    }
}

// MARK: Private

private final class ParentSubqueryEagerLoad<To>: EagerLoadRequest where To: GenericModel {
    typealias Loader = (Database, [To.IDValue]) -> EventLoopFuture<[To]>

    let key: String
    let loader: Loader
    var storage: [To.IDValue: To]

    var description: String {
        return self.storage.description
    }

    private init(key: String, loader: @escaping Loader) {
        self.storage = [:]
        self.loader = loader
        self.key = key
    }

    func prepare(query: inout DatabaseQuery) {
        // no preparation needed
    }

    func run(models: [AnyModel], on database: Database) -> EventLoopFuture<Void> {
        let ids: [To.IDValue] = models
            .compactMap { try! $0.anyID.cachedOutput!.decode(self.key, as: To.IDValue?.self) }

        guard !ids.isEmpty else {
            return database.eventLoop.makeSucceededFuture(())
        }

        let uniqueIDs = Array(Set(ids))
        return self.loader(database, uniqueIDs).map { new in
            new.forEach { model in
                guard let id = model.id else { return }
                self.storage[id] = model
            }
        }
    }

    func get(id: To.IDValue) throws -> Parent<To>.EagerLoaded {
        return self.storage[id].map(Parent<To>.EagerLoaded.loaded) ?? .notLoaded
    }
}


// MARK: - Model Loaders

extension ParentSubqueryEagerLoad where To: Model {
    convenience init(key: String) {
        let loader: Loader = { database, ids -> EventLoopFuture<[To]> in
            return To.query(on: database).filter(key, in: ids).all()
        }

        self.init(key: key, loader: loader)
    }
}

extension ParentSubqueryEagerLoad where To: OptionalType, To.Wrapped: Model {
    convenience init(key: String) {
        let loader: Loader = { database, ids -> EventLoopFuture<[To]> in
            return To.Wrapped.query(on: database).filter(key, in: ids).all().map { models in models as! [To] }
        }

        self.init(key: key, loader: loader)
    }
}
