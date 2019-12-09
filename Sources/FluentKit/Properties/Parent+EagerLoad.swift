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
        typealias Loader = (Database, Set<To.StoredIDValue>) -> EventLoopFuture<[To]>

        let key: String
        let loader: Loader

        var storage: [To.StoredIDValue: Parent<To>.EagerLoaded]

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
            self.storage = models.reduce(into: [:]) { storage, model in
                let parent = try! model.anyID.cachedOutput!.decode(self.key, as: To.StoredIDValue.self)
                storage[parent] = To.defaultEagerLoaded(for: parent)
            }

            if self.storage.isEmpty {
                return database.eventLoop.makeSucceededFuture(())
            }

            let uniqueIDs = Set(self.storage.keys)
            return self.loader(database, uniqueIDs).map { related in
                related.forEach { model in
                    self.storage[model.storedID] = .loaded(model)
                }
            }
        }

        func get(id: To.StoredIDValue) throws -> Parent<To>.EagerLoaded {
            return self.storage[id] ?? .notLoaded
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
