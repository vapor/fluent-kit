@propertyWrapper
public final class Parent<To>: AnyField, AnyEagerLoadable where To: ModelIdentifiable {
    typealias Implementation = AnyProperty & AnyEagerLoadable

    @Field public var id: To.IDValue

    private var eagerLoadedValue: To?
    private var implemntation: ParentImplementation!

    var key: String { return self.$id.key }
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
            if _isOptional(To.self) { return Void?.none as! To }
            throw FluentError.missingEagerLoad(name: self.implemntation.schema)
        }
        return eagerLoaded
    }

    // MARK: - Override

    public func get(on database: Database) -> EventLoopFuture<To> {
        return self.implemntation.get(on: database).map { $0 as! To }
    }

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

    func get(on database: Database) -> EventLoopFuture<Any>
}

// MARK: - Required

extension Parent where To: Model {
    public convenience init(key: String) {
        self.init(id: Field<To.IDValue>(key: key), implemntation: Required.init(parent:))
    }

    private final class Required: ParentImplementation {
        let parent: Parent<To>

        var schema: String { To.schema }
        var key: String { self.parent.key }
        var id: To.IDValue { self.parent.id }

        init(parent: Parent<To>) {
            self.parent = parent
        }

        private func query(on database: Database) -> QueryBuilder<To> {
            return To.query(on: database).filter(self.key, .equal, self.id)
        }

        internal func get(on database: Database) -> EventLoopFuture<Any> {
            return self.query(on: database).first().flatMapThrowing { parent in
                guard let parent = parent else { throw FluentError.missingParent }
                return parent
            }
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

            if let join = request as? JoinEagerLoad<To> {
                self.parent.eagerLoadedValue = try join.get(id: self.id)
            } else if let subquery = request as? SubqueryEagerLoad<To> {
                self.parent.eagerLoadedValue = try subquery.get(id: self.id)
            } else {
                fatalError("unsupported eagerload request: \(request)")
            }
        }

        func eagerLoad(to eagerLoads: EagerLoads, method: EagerLoadMethod, label: String) {
            switch method {
            case .subquery:
                eagerLoads.requests[label] = SubqueryEagerLoad<To>(key: self.key)
            case .join:
                eagerLoads.requests[label] = JoinEagerLoad<To>(key: self.key)
            }
        }
    }
}


// MARK: - Optional

extension Parent where To: OptionalType, To.Wrapped: Model {
    public convenience init(key: String) {
        self.init(id: Field<To.IDValue>(key: key), implemntation: Optional.init(parent:))
    }

    private final class Optional: ParentImplementation {
        let parent: Parent<To>

        var schema: String { To.Wrapped.schema }
        var key: String { self.parent.key }
        var id: To.IDValue { self.parent.id }

        init(parent: Parent<To>) {
            self.parent = parent
        }

        private func query(on database: Database) -> QueryBuilder<To.Wrapped> {
            return To.Wrapped.query(on: database).filter(self.key, .equal, self.id)
        }

        func get(on database: Database) -> EventLoopFuture<Any> {
            return self.query(on: database).first().map { $0 as Any }
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
            guard let id = self.id as? To.Wrapped.IDValue, let request = eagerLoads.requests[label] else {
                return
            }

            if let join = request as? JoinEagerLoad<To.Wrapped> {
                self.parent.eagerLoadedValue = try join.get(id: id) as? To
            } else if let subquery = request as? SubqueryEagerLoad<To.Wrapped> {
                self.parent.eagerLoadedValue = try subquery.get(id: id) as? To
            } else {
                fatalError("unsupported eagerload request: \(request)")
            }
        }

        func eagerLoad(to eagerLoads: EagerLoads, method: EagerLoadMethod, label: String) {
            switch method {
            case .subquery:
                eagerLoads.requests[label] = SubqueryEagerLoad<To.Wrapped>(key: self.key)
            case .join:
                eagerLoads.requests[label] = JoinEagerLoad<To.Wrapped>(key: self.key)
            }
        }
    }
}


// MARK: - Eager Loaders

private final class SubqueryEagerLoad<To>: EagerLoadRequest where To: Model {
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

private final class JoinEagerLoad<To>: EagerLoadRequest where To: Model {
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
        // we can assume query.schema since eager loading
        // is only allowed on the base schema
        query.joins.append(.model(
            foreign: .field(path: [To.key(for: \._$id)], schema: To.schema, alias: nil),
            local: .field(path: [self.key], schema: query.schema, alias: nil),
            method: .inner
        ))
        query.fields += To().fields.map { (_, field) in
            return .field(
                path: [field.key],
                schema: To.schema,
                alias: To.schema + "_" + field.key
            )
        }
    }

    func run(models: [AnyModel], on database: Database) -> EventLoopFuture<Void> {
        do {
            self.storage = try models.map { child in
                return try child.joined(To.self)
            }
            return database.eventLoop.makeSucceededFuture(())
        } catch {
            return database.eventLoop.makeFailedFuture(error)
        }
    }

    func get(id: To.IDValue) throws -> To? {
        return self.storage.filter { parent in
            return parent.id == id
        }.first
    }
}


// MARK: - Optional Model Identifiable

extension Optional: ModelIdentifiable where Wrapped: ModelIdentifiable {
    public typealias IDValue = Wrapped.IDValue

    public var id: Wrapped.IDValue? {
        get { self?.id }
        set { self?.id = newValue }
    }
}
