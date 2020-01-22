@propertyWrapper
public final class Children<From, To>: AnyProperty
    where From: ModelIdentifiable & Codable & CustomStringConvertible, To: Model
{
    // MARK: ID

    let parentKey: KeyPath<To, Parent<From>>
    let parentID: () -> String

    private var eagerLoadedValue: [To]?
    private var idValue: From.IDValue?

    // MARK: Wrapper

    private init(parentKey: KeyPath<To, Parent<From>>, parentID: @autoclosure @escaping () -> String) {
        self.parentKey = parentKey
        self.parentID = parentID
    }

    public var wrappedValue: [To] {
        get {
            guard let eagerLoaded = self.eagerLoadedValue else {
                fatalError("Children relation not eager loaded, use $ prefix to access")
            }
            return eagerLoaded
        }
        set { fatalError("Use $ prefix to access") }
    }

    public var projectedValue: Children<From, To> {
        return self
    }

    public var fromId: From.IDValue? {
        return self.idValue
    }

    // MARK: Query

    public func query(on database: Database) throws -> QueryBuilder<To> {
        guard let id = self.idValue else {
            fatalError("Cannot query children relation from unsaved model.")
        }
        let builder = To.query(on: database)
        builder.filter(self.parentKey.appending(path: \.$id) == id)
        return builder
    }

    // MARK: Property

    func output(from output: DatabaseOutput) throws {
        if output.contains(self.parentID()) {
            self.idValue = try output.decode(self.parentID(), as: From.IDValue.self)
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


extension Children: EagerLoadable {
    public var eagerLoaded: [To]? {
        self.eagerLoadedValue
    }

    public func eagerLoad<Model>(to builder: QueryBuilder<Model>)
        where Model: FluentKit.Model
    {
        builder.eagerLoads.requests[self.eagerLoadKey] = SubqueryEagerLoad(self.parentKey)
    }
}

extension Children: AnyEagerLoadable {
    var eagerLoadKey: String {
        let ref = To()
        return "c:\(To.schema):\(ref[keyPath: self.parentKey].key)"
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
            fatalError("unsupported eagerload request: \(type(of: request))")
        }
    }

    final class SubqueryEagerLoad: EagerLoadRequest {
        var storage: [To]
        let parentKey: KeyPath<To, Parent<From>>

        var description: String {
            return self.storage.description
        }

        init(_ parentKey: KeyPath<To, Parent<From>>) {
            self.storage = []
            self.parentKey = parentKey
        }

        func prepare(query: inout DatabaseQuery) {
            // do nothing
        }

        func run(models: [AnyModel], on database: Database) -> EventLoopFuture<Void> {
            let ids = models.compactMap { ($0 as? From)?.id }

            let builder = To.query(on: database)
            builder.filter(self.parentKey.appending(path: \.$id), in: Set(ids))

            return builder.all()
                .map { (children: [To]) -> Void in
                    self.storage = children
                }
        }

        func get(id: From.IDValue) throws -> [To] {
            return self.storage.filter { child in child[keyPath: self.parentKey].id == id }
        }
    }
}

extension Children where From: Model {
    public convenience init(for parent: KeyPath<To, Parent<From>>) {
        self.init(parentKey: parent, parentID: From.key(for: \._$id))
    }
}

extension Children where From: OptionalType, From.Wrapped: Model {
    public convenience init(for parent: KeyPath<To, Parent<From>>) {
        self.init(parentKey: parent, parentID: From.Wrapped.key(for: \._$id))
    }
}
