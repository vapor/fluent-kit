@propertyWrapper
public final class Parent<To>: AnyField, AnyEagerLoadable where To: ModelIdentifiable {
    typealias Implementation = AnyProperty & AnyEagerLoadable

    @Field public var id: To.IDValue
    public var key: String { return self.$id.key }

    private var eagerLoadedValue: To?
    private var implemntation: ParentImplementation!

    var inputValue: DatabaseQuery.Value? {
        get { self.$id.inputValue }
        set { self.$id.inputValue = newValue }
    }

    public var wrappedValue: To {
        guard let value = self.eagerLoadedValue else {
            if _isOptional(To.self) { return Void?.none as! To }
            fatalError("Parent relation not eager loaded, use $ prefix to access")
        }
        return value
    }

    public var projectedValue: Parent<To> { self }

    private init(id: Field<To.IDValue>, implemntation: (Parent<To>) -> ParentImplementation) {
        self._id = id
        self.implemntation = nil

        self.implemntation = implemntation(self)
    }

    func output(from output: DatabaseOutput) throws {
        return try self._id.output(from: output)
    }

    public func eagerLoaded() throws -> To {
        guard let eagerLoaded = self.eagerLoadedValue else {
            throw FluentError.missingEagerLoad(name: self.implemntation.schema)
        }
        return eagerLoaded
    }

    // MARK: - Override

    func encode(to encoder: Encoder) throws {
        try self.implemntation.encode(to: encoder)
    }

    func decode(from decoder: Decoder) throws {
        try self.implemntation.decode(from: decoder)
    }

    func eagerLoad(from eagerLoads: EagerLoads, label: String) throws {
        try self.implemntation.eagerLoad(from: eagerLoads, label: label)
    }

    func eagerLoad(to eagerLoads: EagerLoads, method: EagerLoadMethod, label: String) {
        self.implemntation.eagerLoad(to: eagerLoads, method: method, label: label)
    }
}

protocol ParentImplementation: AnyEagerLoadable {
    var schema: String { get }
}

// MARK: - Required

extension Parent where To: Model {
    public convenience init(key: String) {
        self.init(id: Field<To.IDValue>(key: key), implemntation: Required.init(parent:))
    }

    public func query(on database: Database) -> QueryBuilder<To> {
        return To.query(on: database).filter(self.key, .equal, self.id)
    }

    public func get(on database: Database) -> EventLoopFuture<To> {
        return self.query(on: database).first().flatMapThrowing { parent in
            guard let parent = parent else { throw FluentError.missingParent }
            return parent
        }
    }

    private final class Required: ParentImplementation {
        let parent: Parent<To>

        var schema: String { To.schema }
        var key: String { self.parent.key }
        var id: To.IDValue { self.parent.id }

        init(parent: Parent<To>) {
            self.parent = parent
        }

        func output(from output: DatabaseOutput) throws {
            try self.parent._id.output(from: output)
        }

        func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            if let parent = self.parent.eagerLoadedValue {
                try container.encode(parent)
            } else {
                try container.encode([
                    To.key(for: \._$id): self.id
                ])
            }
        }

        func decode(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: _ModelCodingKey.self)
            try self.parent._id.decode(from: container.superDecoder(forKey: .string(To.key(for: \._$id))))
            // TODO: allow for nested decoding
        }

        func eagerLoad(from eagerLoads: EagerLoads, label: String) throws {
            guard let request = eagerLoads.requests[label] else {
                return
            }

            if let join = request as? JoinEagerLoad {
                self.parent.eagerLoadedValue = try join.get(id: self.id)
            } else if let subquery = request as? SubqueryEagerLoad {
                self.parent.eagerLoadedValue = try subquery.get(id: self.id)
            } else {
                fatalError("unsupported eagerload request: \(request)")
            }
        }

        func eagerLoad(to eagerLoads: EagerLoads, method: EagerLoadMethod, label: String) {
            switch method {
            case .subquery:
                eagerLoads.requests[label] = SubqueryEagerLoad(key: self.key)
            case .join:
                eagerLoads.requests[label] = JoinEagerLoad(key: self.key)
            }
        }
    }
}


// MARK: - Optional

extension Parent where To: OptionalType, To.Wrapped: Model {
    public convenience init(key: String) {
        self.init(id: Field<To.IDValue>(key: key), implemntation: Optional.init(parent:))
    }

    public func query(on database: Database) -> QueryBuilder<To.Wrapped> {
        return To.Wrapped.query(on: database).filter(self.key, .equal, self.id)
    }

    public func get(on database: Database) -> EventLoopFuture<To> {
        return self.query(on: database).first().map { $0 as! To }
    }

    private final class Optional: ParentImplementation {
        let parent: Parent<To>

        var schema: String { To.Wrapped.schema }
        var key: String { self.parent.key }
        var id: To.IDValue { self.parent.id }

        init(parent: Parent<To>) {
            self.parent = parent
        }

        func output(from output: DatabaseOutput) throws {
            try self.parent._id.output(from: output)
        }

        func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            if
                let optional = self.parent.eagerLoadedValue as? Swift.Optional<To.Wrapped>,
                let parent = optional
            {
                try container.encode(parent)
            } else {
                try container.encode([
                    To.Wrapped.key(for: \._$id): self.id
                ])
            }
        }

        func decode(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: _ModelCodingKey.self)
            try self.parent._id.decode(from:
                container.superDecoder(forKey: .string(To.Wrapped.key(for: \._$id)))
            )
            // TODO: allow for nested decoding
        }

        func eagerLoad(from eagerLoads: EagerLoads, label: String) throws {
            guard let request = eagerLoads.requests[label] else {
                return
            }

            if let join = request as? JoinEagerLoad {
                self.parent.eagerLoadedValue = try join.get(id: self.id)
            } else if let subquery = request as? SubqueryEagerLoad {
                self.parent.eagerLoadedValue = try subquery.get(id: self.id)
            } else {
                fatalError("unsupported eagerload request: \(request)")
            }
        }

        func eagerLoad(to eagerLoads: EagerLoads, method: EagerLoadMethod, label: String) {
            switch method {
            case .subquery:
                eagerLoads.requests[label] = SubqueryEagerLoad(key: self.key)
            case .join:
                eagerLoads.requests[label] = JoinEagerLoad(key: self.key)
            }
        }
    }
}

// MARK: - Optional Model Identifiable

extension Optional: ModelIdentifiable where Wrapped: ModelIdentifiable {
    public typealias IDValue = Wrapped.IDValue?

    public var id: Wrapped.IDValue?? {
        get { self?.id }
        set { self?.id = newValue ?? nil }
    }
}
