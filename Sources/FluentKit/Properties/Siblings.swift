@propertyWrapper
public final class Siblings<From, To, Through>: AnyProperty
    where From: Model, To: Model, Through: Model
{

    private let from: KeyPath<Through, Parent<From>>
    private let to: KeyPath<Through, Parent<To>>
    private var idValue: From.IDValue?
    private var eagerLoadedValue: [To]?

    public init(
        through: Through.Type,
        from: KeyPath<Through, Parent<From>>,
        to: KeyPath<Through, Parent<To>>
    ) {
        self.from = from
        self.to = to
    }

    public var wrappedValue: [To] {
        get {
            guard let eagerLoaded = self.eagerLoadedValue else {
                fatalError("Siblings relation not eager loaded, use $ prefix to access")
            }
            return eagerLoaded
        }
        set { fatalError("Use $ prefix to modify siblings relation") }
    }

    public var projectedValue: Siblings<From, To, Through> {
        return self
    }

    // MARK: Operations

    public func attach(
        _ to: To,
        on database: Database,
        _ edit: (Through) -> () = { _ in }
    ) -> EventLoopFuture<Void> {
        guard let fromID = self.idValue else {
            fatalError("Cannot attach siblings relation to unsaved model.")
        }
        guard let toID = to.id else {
            fatalError("Cannot attach unsaved model.")
        }

        let pivot = Through()
        pivot[keyPath: self.from].id = fromID
        pivot[keyPath: self.to].id = toID
        edit(pivot)
        return pivot.save(on: database)
    }

    public func detach(_ to: To, on database: Database) -> EventLoopFuture<Void> {
        guard let fromID = self.idValue else {
            fatalError("Cannot attach siblings relation to unsaved model.")
        }
        guard let toID = to.id else {
            fatalError("Cannot attach unsaved model.")
        }

        return Through.query(on: database)
            .filter(self.from.appending(path: \.$id) == fromID)
            .filter(self.to.appending(path: \.$id) == toID)
            .delete()
    }

    // MARK: Query

    public func query(on database: Database) throws -> QueryBuilder<To> {
        guard let fromID = self.idValue else {
            fatalError("Cannot query siblings relation from unsaved model.")
        }

        return To.query(on: database)
            .join(self.to)
            .filter(Through.self, self.from.appending(path: \.$id) == fromID)
    }

    func output(from output: DatabaseOutput) throws {
        let key = From.key(for: \._$id)
        if output.contains(key) {
            self.idValue = try output.decode(key, as: From.IDValue.self)
        }
    }

    // MARK: Codable

    func encode(to encoder: Encoder) throws {
        if let rows = self.eagerLoadedValue {
            var container = encoder.singleValueContainer()
            try container.encode(rows)
        }
    }

    func decode(from decoder: Decoder) throws {
        // don't decode
    }
}


extension Siblings: EagerLoadable {
    public var eagerLoaded: [To]? {
        self.eagerLoadedValue
    }

    public func eagerLoad<Model>(to builder: QueryBuilder<Model>)
        where Model: FluentKit.Model
    {
        builder.eagerLoads.requests[self.eagerLoadKey] = SubqueryEagerLoad(
            from: self.from, to: self.to
        )
    }
}


extension Siblings: AnyEagerLoadable {
    var eagerLoadKey: String {
        let ref = Through()
        return "s:" + ref[keyPath: self.from].key + "+" + ref[keyPath: self.to].key
    }

    var eagerLoadValueDescription: CustomStringConvertible? {
        return self.eagerLoadedValue
    }

    func eagerLoad(from eagerLoads: EagerLoads) throws {
        guard let request = eagerLoads.requests[self.eagerLoadKey] else {
            return
        }
        if let subquery = request as? SubqueryEagerLoad {
            self.eagerLoadedValue = try subquery.get(id: self.idValue!)
        } else {
            fatalError("unsupported eagerload request: \(request)")
        }
    }

    final class SubqueryEagerLoad: EagerLoadRequest {
        var storage: [To]
        private let from: KeyPath<Through, Parent<From>>
        private let to: KeyPath<Through, Parent<To>>

        var description: String {
            return self.storage.description
        }

        init(from: KeyPath<Through, Parent<From>>, to: KeyPath<Through, Parent<To>>) {
            self.storage = []
            self.from = from
            self.to = to
        }

        func prepare(query: inout DatabaseQuery) {
            // do nothing
        }

        func run(models: [AnyModel], on database: Database) -> EventLoopFuture<Void> {
            let ids: [From.IDValue] = models
                .map { $0 as! From }
                .map { $0.id! }

            return To.query(on: database)
                .join(self.to)
                .filter(self.from.appending(path: \.$id), in: Set(ids))
                .all()
                .map { (to: [To]) in
                    self.storage = to
                }
        }

        func get(id: From.IDValue) throws -> [To] {
            return try self.storage.filter { to in
                return try to.joined(Through.self)[keyPath: self.from].id == id
            }
        }
    }
}
