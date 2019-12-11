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

extension Parent: EagerLoadable {
    public var eagerLoaded: To? {
        self.eagerLoadedValue
    }

    public func eagerLoad<Model>(to builder: QueryBuilder<Model>)
        where Model: FluentKit.Model
    {
        builder.eagerLoads.requests[self.eagerLoadKey] = ParentSubqueryEagerLoad<To>(
            key: self.$id.key
        )
    }
}


extension OptionalParent: AnyEagerLoadable {
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

        self.didEagerLoad = true
        guard let id = self.id else {
            return
        }

        if let subquery = request as? ParentSubqueryEagerLoad<To> {
            self.eagerLoadedValue = try subquery.get(id: id)
        } else {
            fatalError("unsupported eagerload request: \(request)")
        }
    }
}

extension OptionalParent: EagerLoadable {
    public var eagerLoaded: To? {
        self.eagerLoadedValue
    }

    public func eagerLoad<Model>(to builder: QueryBuilder<Model>)
        where Model: FluentKit.Model
    {
        builder.eagerLoads.requests[self.eagerLoadKey] = ParentSubqueryEagerLoad<To>(
            key: self.$id.key
        )
    }
}

// MARK: Private

private final class ParentSubqueryEagerLoad<To>: EagerLoadRequest
    where To: Model
{
    let key: String
    var storage: [To]

    var description: String {
        return self.storage.description
    }

    init(key: String) {
        self.storage = []
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
        return To.query(on: database)
            .filter(To.key(for: \._$id), in: uniqueIDs)
            .all()
            .map { self.storage = $0 }
    }

    func get(id: To.IDValue) throws -> To? {
        return self.storage.filter { parent in
            return parent.id == id
        }.first
    }
}
