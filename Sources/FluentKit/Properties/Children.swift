@propertyWrapper
public final class Children<From, To>: AnyProperty
    where From: Model, To: Model
{
    // MARK: ID

    enum Key {
        case required(KeyPath<To, Parent<From>>)
        case optional(KeyPath<To, OptionalParent<From>>)
    }

    let parentKey: Key
    var idValue: From.IDValue?

    // MARK: Wrapper
    public var value: [To]?

    public init(for parent: KeyPath<To, Parent<From>>) {
        self.parentKey = .required(parent)
    }

    public init(for optionalParent: KeyPath<To, OptionalParent<From>>) {
        self.parentKey = .optional(optionalParent)
    }

    public var wrappedValue: [To] {
        get {
            guard let value = self.value else {
                fatalError("Children relation not loaded.")
            }
            return value
        }
        set {
            fatalError("Children relation is get-only.")
        }
    }

    public var projectedValue: Children<From, To> {
        return self
    }
    
    public var fromId: From.IDValue? {
        return self.idValue
    }

    // MARK: Query

    public func query(on database: Database) -> QueryBuilder<To> {
        guard let id = self.idValue else {
            fatalError("Cannot query children relation from unsaved model.")
        }
        let builder = To.query(on: database)
        switch self.parentKey {
        case .optional(let optional):
            builder.filter(optional.appending(path: \.$id) == id)
        case .required(let required):
            builder.filter(required.appending(path: \.$id) == id)
        }
        return builder
    }

    // MARK: Property

    func output(from output: DatabaseOutput) throws {
        let key = From.key(for: \._$id)
        if output.contains(key) {
            self.idValue = try output.decode(key, as: From.IDValue.self)
        }
    }

    // MARK: Codable
    func encode(to encoder: Encoder) throws {
        if let rows = self.value {
            var container = encoder.singleValueContainer()
            try container.encode(rows)
        }
    }

    func decode(from decoder: Decoder) throws {
        // don't decode
    }
}

extension Children.Key: CustomStringConvertible {
    var description: String {
        switch self {
        case .optional(let keyPath):
            return To.key(for: keyPath)
        case .required(let keyPath):
            return To.key(for: keyPath)
        }
    }
}

extension Children: Relation {
    public var name: String {
        "Children<\(From.self), \(To.self)>(for: \(self.parentKey))"
    }

    public func load(on database: Database) -> EventLoopFuture<Void> {
        self.query(on: database).all().map {
            self.value = $0
        }
    }
}

extension Children: EagerLoadable {
    public func eagerLoad<Model>(to builder: QueryBuilder<Model>)
        where Model: FluentKit.Model
    {
        builder.eagerLoads.requests[self.eagerLoadKey] = SubqueryEagerLoad(self.parentKey)
    }
}

extension Children: AnyEagerLoadable {
    var eagerLoadKey: String {
        let ref = To()
        switch self.parentKey {
        case .optional(let optional):
            return "c:\(To.schema):\(ref[keyPath: optional].key)"
        case .required(let required):
            return "c:\(To.schema):\(ref[keyPath: required].key)"
        }
    }

    var eagerLoadValueDescription: CustomStringConvertible? {
        return self.value
    }

    func eagerLoad(from eagerLoads: EagerLoads) throws {
        guard let request = eagerLoads.requests[self.eagerLoadKey] else {
            return
        }
        if let subquery = request as? SubqueryEagerLoad {
            self.value = try subquery.get(id: self.idValue!)
        } else {
            fatalError("unsupported eagerload request: \(type(of: request))")
        }
    }

    final class SubqueryEagerLoad: EagerLoadRequest {
        var storage: [To]
        let parentKey: Key

        var description: String {
            return self.storage.description
        }

        init(_ parentKey: Key) {
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

            let builder = To.query(on: database)
            switch self.parentKey {
            case .optional(let optional):
                builder.filter(optional.appending(path: \.$id), in: Set(ids))
            case .required(let required):
                builder.filter(required.appending(path: \.$id), in: Set(ids))
            }
            return builder.all()
                .map { (children: [To]) -> Void in
                    self.storage = children
                }
        }

        func get(id: From.IDValue) throws -> [To] {
            return self.storage.filter { child in
                switch self.parentKey {
                case .optional(let optional):
                    return child[keyPath: optional].id == id
                case .required(let required):
                    return child[keyPath: required].id == id
                }
            }
        }
    }
}
