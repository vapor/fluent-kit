@propertyWrapper
public final class Parent<To>: AnyField, AnyEagerLoadable where To: ModelIdentifiable {
    @Field public var id: To.IDValue

    private var eagerLoadedValue: To?

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

    private init(id: Field<To.IDValue>) {
        self._id = id
    }

    func output(from output: DatabaseOutput) throws {
        return try self._id.output(from: output)
    }

    public func eagerLoaded() throws -> To {
        guard let eagerLoaded = self.eagerLoadedValue else {
            if _isOptional(To.self) { return Void?.none as! To }
            throw FluentError.missingEagerLoad(name: self.parentSchema)
        }
        return eagerLoaded
    }

    // MARK: - Override

    var parentSchema: String { fatalError("\(Self.self).To type must be Model or Optional<Model>") }

    public func get(on database: Database) -> EventLoopFuture<To> {
        fatalError("\(Self.self).To type must be Model or Optional<Model>")
    }

    func encode(to encoder: Encoder) throws {
        fatalError("\(Self.self).To type must be Model or Optional<Model>")
    }

    func decode(from decoder: Decoder) throws {
        fatalError("\(Self.self).To type must be Model or Optional<Model>")
    }

    func eagerLoad(from eagerLoads: EagerLoads, label: String) throws {
        fatalError("\(Self.self).To type must be Model or Optional<Model>")
    }

    func eagerLoad(to eagerLoads: EagerLoads, method: EagerLoadMethod, label: String) {
        fatalError("\(Self.self).To type must be Model or Optional<Model>")
    }
}


// MARK: - Required

extension Parent where To: Model {
    var parentSchema: String { To.schema.self }

    public convenience init(key: String) {
        self.init(id: Field<To.IDValue>(key: key))
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

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        if let parent = self.eagerLoadedValue {
            try container.encode(parent)
        } else {
            try container.encode([
                To.key(for: \._$id): self.id
            ])
        }
    }

    func decode(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: _ModelCodingKey.self)
        try self._id.decode(from: container.superDecoder(forKey: .string(To.key(for: \._$id))))
        // TODO: allow for nested decoding
    }

    func eagerLoad(from eagerLoads: EagerLoads, label: String) throws {
        guard let request = eagerLoads.requests[label] else {
            return
        }

        if let join = request as? JoinEagerLoad<To> {
            self.eagerLoadedValue = try join.get(id: self.id)
        } else if let subquery = request as? SubqueryEagerLoad<To> {
            self.eagerLoadedValue = try subquery.get(id: self.id)
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


// MARK: - Optional

extension Parent where To: OptionalType, To.Wrapped: Model {
    var parentSchema: String { To.Wrapped.schema.self }

    public convenience init(key: String) {
        self.init(id: Field<To.IDValue>(key: key))
    }

    public func query(on database: Database) -> QueryBuilder<To.Wrapped> {
        return To.Wrapped.query(on: database).filter(self.key, .equal, self.id)
    }

    public func get(on database: Database) -> EventLoopFuture<To> {
        return self.query(on: database).first().map { model in model as! To }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        if let optional = self.eagerLoadedValue as? Optional<To.Wrapped>, let parent = optional {
            try container.encode(parent)
        } else {
            try container.encode([
                To.Wrapped.key(for: \._$id): self.id
            ])
        }
    }

    func decode(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: _ModelCodingKey.self)
        try self._id.decode(from: container.superDecoder(forKey: .string(To.Wrapped.key(for: \._$id))))
        // TODO: allow for nested decoding
    }

    func eagerLoad(from eagerLoads: EagerLoads, label: String) throws {
        guard let id = self.id as? To.Wrapped.IDValue, let request = eagerLoads.requests[label] else {
            return
        }

        if let join = request as? JoinEagerLoad<To.Wrapped> {
            self.eagerLoadedValue = try join.get(id: id) as? To
        } else if let subquery = request as? SubqueryEagerLoad<To.Wrapped> {
            self.eagerLoadedValue = try subquery.get(id: id) as? To
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
