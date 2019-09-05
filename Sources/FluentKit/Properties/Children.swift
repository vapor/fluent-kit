@propertyWrapper
public final class Children<F, T>: AnyProperty, AnyEagerLoadable
    where F: ModelIdentifiable, T: Model
{
    public typealias From = F
    public typealias To = T

    // MARK: ID

    let parentKey: KeyPath<To, Parent<From>>
    private var eagerLoadedValue: [To]?
    private var idValue: From.IDValue?
    private var implementation: ChildrenImplementation!

    // MARK: Wrapper

    // KeyPath<User, Parent<Agency?>>
    private init(from parentKey: KeyPath<To, Parent<From>>, implementation: (Children<From, To>) -> ChildrenImplementation) {
        self.parentKey = parentKey
        self.implementation = nil

        self.implementation = implementation(self)
    }

    public var wrappedValue: [To] {
        get {
            guard let values = self.eagerLoadedValue else {
                fatalError("Child relations not eager loaded, use $ prefix to access")
            }
            return values
        }
        set { fatalError("Use $ prefix to access") }
    }

    public var projectedValue: Children<From, To> {
        return self
    }

    public func eagerLoaded() throws -> [To] {
        guard let rows = self.eagerLoadedValue else {
            if _isOptional(To.self) { return [] }
            throw FluentError.missingEagerLoad(name: self.implementation.schema)
        }
        return rows
    }

    public func query(on database: Database) throws -> QueryBuilder<To> {
        guard let id = self.idValue else {
            fatalError("Cannot query children relation from unsaved model.")
        }

        return To.query(on: database)
            .filter(self.parentKey.appending(path: \.$id) == id)
    }

    // MARK: - Override

    func output(from output: DatabaseOutput) throws {
        try self.implementation.output(from: output)
    }

    func encode(to encoder: Encoder) throws {
        try self.implementation.encode(to: encoder)
    }

    func decode(from decoder: Decoder) throws {
        try self.implementation.decode(from: decoder)
    }

    func eagerLoad(from eagerLoads: EagerLoads, label: String) throws {
        try self.implementation.eagerLoad(from: eagerLoads, label: label)
    }

    func eagerLoad(to eagerLoads: EagerLoads, method: EagerLoadMethod, label: String) {
        self.implementation.eagerLoad(to: eagerLoads, method: method, label: label)
    }
}

private protocol ChildrenImplementation: AnyEagerLoadable {
    var schema: String { get }
}

extension ChildrenImplementation {
    func decode(from decoder: Decoder) throws { /* don't decode */ }
}

extension Children where From: Model {
    public convenience init(from parentKey: KeyPath<To, Parent<From>>) {
        self.init(from: parentKey, implementation: Required.init(children:))
    }

    private final class Required: ChildrenImplementation {
        let children: Children<From, To>

        var schema: String { To.schema }

        init(children: Children<From, To>) {
            self.children = children
        }

        func output(from output: DatabaseOutput) throws {
            let key = From.key(for: \._$id)
            if output.contains(field: key) {
                self.children.idValue = try output.decode(field: key, as: From.IDValue.self)
            }
        }

        // MARK: Codable
        func encode(to encoder: Encoder) throws {
            if let rows = self.children.eagerLoadedValue {
                var container = encoder.singleValueContainer()
                try container.encode(rows)
            }
        }

        // MARK: Eager Load

        func eagerLoad(from eagerLoads: EagerLoads, label: String) throws {
            guard let request = eagerLoads.requests[label] else {
                return
            }
            if let subquery = request as? SubqueryEagerLoad {
                self.children.eagerLoadedValue = try subquery.get(id: self.children.idValue!)
            } else {
                fatalError("unsupported eagerload request: \(request)")
            }
        }

        func eagerLoad(to eagerLoads: EagerLoads, method: EagerLoadMethod, label: String) {
            switch method {
            case .subquery:
                eagerLoads.requests[label] = SubqueryEagerLoad(self.children.parentKey)
            case .join:
                fatalError("Eager loading children using join is not yet supported")
            }
        }
    }
}

extension Children where From: OptionalType & Encodable, From.Wrapped: Model {
    public convenience init(from parentKey: KeyPath<To, Parent<From>>) {
        self.init(from: parentKey, implementation: Optional.init(children:))
    }

    private final class Optional: ChildrenImplementation {
        let children: Children<From, To>

        var schema: String { To.schema }

        init(children: Children<From, To>) {
            self.children = children
        }

        func output(from output: DatabaseOutput) throws {
            let key = From.Wrapped.key(for: \._$id)
            if output.contains(field: key) {
                self.children.idValue = try output.decode(field: key, as: From.IDValue.self)
            }
        }

        // MARK: Codable
        func encode(to encoder: Encoder) throws {
            if let rows = self.children.eagerLoadedValue {
                var container = encoder.singleValueContainer()
                try container.encode(rows)
            }
        }

        // MARK: Eager Load

        func eagerLoad(from eagerLoads: EagerLoads, label: String) throws {
            guard let request = eagerLoads.requests[label] else {
                return
            }
            if let subquery = request as? SubqueryEagerLoad {
                self.children.eagerLoadedValue = try subquery.get(id: self.children.idValue!)
            } else {
                fatalError("unsupported eagerload request: \(request)")
            }
        }

        func eagerLoad(to eagerLoads: EagerLoads, method: EagerLoadMethod, label: String) {
            switch method {
            case .subquery:
                eagerLoads.requests[label] = SubqueryEagerLoad(self.children.parentKey)
            case .join:
                fatalError("Eager loading children using join is not yet supported")
            }
        }
    }
}
