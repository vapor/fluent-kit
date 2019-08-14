@propertyWrapper
public final class Parent<To>: AnyField, AnyEagerLoadable
    where To: Model
{
    // MARK: ID

    public typealias Value = To.IDValue

    private var cachedLabel: String?
    private var eagerLoadedValue: To?

    @Field
    public var id: To.IDValue

    // MARK: Wrapper

    public var wrappedValue: To {
        get {
            guard let eagerLoaded = self.eagerLoadedValue else {
                fatalError("Parent relation not eager loaded, use $ prefix to access")
            }
            return eagerLoaded
        }
        set { fatalError("use $ prefix to access") }
    }

    public var projectedValue: Parent<To> {
        return self
    }

    public init(key: String) {
        self._id = .init(key: key)
    }

    // MARK: Field

    public var key: String {
        return self.$id.key
    }

    // MARK: Query

    public func query(on database: Database) -> QueryBuilder<To> {
        return To.query(on: database)
            .filter(self.key, .equal, self.id)
    }

    public func get(on database: Database) -> EventLoopFuture<To> {
        return self.query(on: database).first().flatMapThrowing { parent in
            guard let parent = parent else {
                throw FluentError.missingParent
            }
            return parent
        }
    }


    // MARK: Field

    var inputValue: DatabaseQuery.Value? {
        get {
            return self.$id.inputValue
        }
        set {
            self.$id.inputValue = newValue
        }
    }

    // MARK: Property

    func output(from output: DatabaseOutput) throws {
        try self.$id.output(from: output)
    }

    // MARK: Eager Loadable

    func eagerLoad(from eagerLoads: EagerLoads, label: String) throws {
        guard let request = eagerLoads.requests[label] else {
            return
        }

        if let join = request as? JoinEagerLoad {
            self.eagerLoadedValue = try join.get(id: self.id)
        } else if let subquery = request as? SubqueryEagerLoad {
            self.eagerLoadedValue = try subquery.get(id: self.id)
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
        try self.$id.decode(from: container.superDecoder(forKey: .string(To.key(for: \._$id))))
        // TODO: allow for nested decoding
    }

    // MARK: Eager Load

    public func eagerLoaded() throws -> To {
        guard let eagerLoaded = self.eagerLoadedValue else {
            throw FluentError.missingEagerLoad(name: To.schema.self)
        }
        return eagerLoaded
    }

    private final class SubqueryEagerLoad: EagerLoadRequest {
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

    final class JoinEagerLoad: EagerLoadRequest {
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
}
