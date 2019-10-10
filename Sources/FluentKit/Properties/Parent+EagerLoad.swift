extension Parent: AnyEagerLoadable {
    var eagerLoadKey: String {
        return self.$id.key
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
        return self.$id.key
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

        if let subquery = request as? ParentSubqueryEagerLoad<To.Wrapped> {
            self.eagerLoadedValue = try subquery.get(id: id)
        } else {
            fatalError("unsupported eagerload request: \(request)")
        }
    }
}

extension OptionalParent: EagerLoadable {
    public func eagerLoad<Model>(to builder: QueryBuilder<Model>)
        where Model: FluentKit.Model
    {
        builder.eagerLoads.requests[self.eagerLoadKey] = ParentSubqueryEagerLoad<To.Wrapped>(
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
        return "\(self.key): \(self.storage)"
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
            .map { try! $0.anyID.cachedOutput!.decode(field: self.key, as: To.IDValue.self) }

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

//private final class ParentJoinEagerLoad<To>: EagerLoadRequest
//    where To: Model
//{
//    let key: String
//    var storage: [To]
//
//    var description: String {
//        return "\(self.key): \(self.storage)"
//    }
//
//    init(key: String) {
//        self.storage = []
//        self.key = key
//    }
//
//    func prepare(query: inout DatabaseQuery) {
//        // we can assume query.schema since eager loading
//        // is only allowed on the base schema
//        query.joins.append(.join(
//            schema: .schema(name: To.schema, alias: nil),
//            foreign: .field(
//                path: [To.key(for: \._$id)],
//                schema: To.schema,
//                alias: nil
//            ),
//            local: .field(
//                path: [self.key],
//                schema: query.schema,
//                alias: nil
//            ),
//            method: .inner
//        ))
//        query.fields += To().fields.map { (_, field) in
//            return .field(
//                path: [field.key],
//                schema: To.schema,
//                alias: To.schema + "_" + field.key
//            )
//        }
//    }
//
//    func run(models: [AnyModel], on database: Database) -> EventLoopFuture<Void> {
//        do {
//            self.storage = try models.map { child in
//                return try child.joined(To.self)
//            }
//            return database.eventLoop.makeSucceededFuture(())
//        } catch {
//            return database.eventLoop.makeFailedFuture(error)
//        }
//    }
//
//    func get(id: To.IDValue) throws -> To? {
//        return self.storage.filter { parent in
//            return parent.id == id
//        }.first
//    }
//}
