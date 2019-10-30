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

        if let subquery = request as? SubqueryEagerLoad {
            self.eagerLoadedValue = try subquery.get(id: id)
        } else {
            fatalError("unsupported eagerload request: \(request)")
        }
    }
}


// MARK: - Eager Loadable

extension Parent: EagerLoadable {
    public func eagerLoad<Model>(to builder: QueryBuilder<Model>) where Model: FluentKit.Model {
        builder.eagerLoads.requests[self.eagerLoadKey] = self.eagerLoadRequest
    }
}

// MARK: Private

extension Parent {
    internal final class SubqueryEagerLoad: EagerLoadRequest {
        typealias Loader = (Database, [To.IDValue]) -> EventLoopFuture<[To]>

        let key: String
        let loader: Loader

        var run: Bool
        var storage: [To.IDValue: Parent<To>.EagerLoaded]

        var description: String {
            return self.storage.description
        }

        private init(key: String, loader: @escaping Loader) {
            self.storage = [:]
            self.loader = loader
            self.run = false
            self.key = key
        }

        func prepare(query: inout DatabaseQuery) {
            // no preparation needed
        }

        func run(models: [AnyModel], on database: Database) -> EventLoopFuture<Void> {
            let ids: [To.IDValue] = models
                .compactMap { try! $0.anyID.cachedOutput!.decode(self.key, as: To.IDValue?.self) }

            guard !ids.isEmpty else {
                self.run = true
                return database.eventLoop.makeSucceededFuture(())
            }

            let uniqueIDs = Array(Set(ids))
            return self.loader(database, uniqueIDs).map { new in
                uniqueIDs.forEach { id in
                    if let model = new.first(where: { model in model.id == id }) {
                        self.storage[id] = .loaded(model)
                    } else if _isOptional(To.self) {
                        self.storage[id] = .loaded(Optional<Void>.none as! To)
                    }
                }

                self.run = true
            }
        }

        func get(id: To.IDValue) throws -> Parent<To>.EagerLoaded {
            guard let loaded = self.storage[id] else {
                if self.run && _isOptional(To.self) {
                    return .loaded(Optional<Void>.none as! To)
                }
                return .notLoaded
            }

            return loaded
        }
    }
}


// MARK: - Model Loaders

extension Parent.SubqueryEagerLoad where To: Model {
    convenience init(key: String) {
        let loader: Loader = { database, ids -> EventLoopFuture<[To]> in
            return To.query(on: database).filter(To.key(for: \._$id), in: ids).all()
        }

        self.init(key: key, loader: loader)
    }
}

extension Parent.SubqueryEagerLoad where To: OptionalType, To.Wrapped: Model {
    convenience init(key: String) {
        let loader: Loader = { database, ids -> EventLoopFuture<[To]> in
            return To.Wrapped.query(on: database).filter(To.Wrapped.key(for: \._$id), in: ids).all().map { models in
                models as! [To]
            }
        }

        self.init(key: key, loader: loader)
    }
}
