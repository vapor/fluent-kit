@propertyWrapper
public final class Children<From, To>: AnyProperty, AnyEagerLoadable
    where From: Model, To: Model
{
    // MARK: ID

    let parentKey: KeyPath<To, Parent<From>>
    private var eagerLoadedValue: [To]?
    private var idValue: From.IDValue?

    // MARK: Wrapper

    public init(from parentKey: KeyPath<To, Parent<From>>) {
        self.parentKey = parentKey
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
        return To.query(on: database)
            .filter(self.parentKey.appending(path: \.$id) == id)
    }

    // MARK: Property

    func output(from output: DatabaseOutput) throws {
        let key = From.key(for: \._$id)
        if output.contains(field: key) {
            self.idValue = try output.decode(field: key, as: From.IDValue.self)
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

    // MARK: Eager Load

    var eagerLoadValueDescription: CustomStringConvertible? {
        return self.eagerLoadedValue
    }

    public func eagerLoaded() throws -> [To] {
        guard let rows = self.eagerLoadedValue else {
            throw FluentError.missingEagerLoad(name: To.schema.self)
        }
        return rows
    }

    func eagerLoad(from eagerLoads: EagerLoads, label: String) throws {
        guard let request = eagerLoads.requests[label] else {
            return
        }
        if let subquery = request as? SubqueryEagerLoad {
            self.eagerLoadedValue = try subquery.get(id: self.idValue!)
        } else {
            fatalError("unsupported eagerload request: \(request)")
        }
    }

    func eagerLoad(to eagerLoads: EagerLoads, method: EagerLoadMethod, label: String) {
        switch method {
        case .subquery:
            eagerLoads.requests[label] = SubqueryEagerLoad(self.parentKey)
        case .join:
            fatalError("Eager loading children using join is not yet supported")
        }
    }

    private final class SubqueryEagerLoad: EagerLoadRequest {
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
            let ids: [From.IDValue] = models
                .map { $0 as! From }
                .map { $0.id! }

            return To.query(on: database)
                .filter(self.parentKey.appending(path: \.$id), in: Set(ids))
                .all()
                .map { (children: [To]) -> Void in
                    self.storage = children
                }
        }

        func get(id: From.IDValue) throws -> [To] {
            return self.storage.filter { child in
                return child[keyPath: self.parentKey].id == id
            }
        }
    }
}


