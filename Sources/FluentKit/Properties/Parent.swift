@propertyWrapper
public final class Parent<P>: AnyField, AnyEagerLoadable
    where P: Model
{
    // MARK: ID

    public typealias Value = P.IDValue

    private var cachedLabel: String?
    private var eagerLoadedValue: P?

    @Field
    public var id: P.IDValue

    // MARK: Wrapper

    public var wrappedValue: P {
        get { fatalError("use $ prefix to access") }
        set { fatalError("use $ prefix to access") }
    }

    public var projectedValue: Parent<P> {
        return self
    }

    public init(_ key: String) {
        self._id = .init(key)
    }

    // MARK: Field

    public var key: String {
        return self.$id.key
    }

    // MARK: Query

    public func query(on database: Database) -> QueryBuilder<P> {
        return P.query(on: database)
            .filter(self.key, .equal, self.id)
    }

    public func get(on database: Database) -> EventLoopFuture<P> {
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
                P.key(for: \._$id): self.id
            ])
        }
    }
    
    func decode(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: _ModelCodingKey.self)
        try self.$id.decode(from: container.superDecoder(forKey: .string(P.key(for: \._$id))))
        // TODO: allow for nested decoding
    }

    // MARK: Eager Load

    public func eagerLoaded() throws -> P {
        guard let eagerLoaded = self.eagerLoadedValue else {
            throw FluentError.missingEagerLoad(name: P.entity.self)
        }
        return eagerLoaded
    }

    private final class SubqueryEagerLoad: EagerLoadRequest {
        let key: String
        var storage: [P]

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
            let ids: [P.IDValue] = models
                .map { try! $0.anyID.cachedOutput!.decode(field: self.key, as: P.IDValue.self) }

            let uniqueIDs = Array(Set(ids))
            return P.query(on: database)
                .filter(P.key(for: \._$id), in: uniqueIDs)
                .all()
                .map { self.storage = $0 }
        }

        func get(id: P.IDValue) throws -> P? {
            return self.storage.filter { parent in
                return parent.id == id
            }.first
        }
    }

    final class JoinEagerLoad: EagerLoadRequest {
        let key: String
        var storage: [P]

        var description: String {
            return "\(self.key): \(self.storage)"
        }

        init(key: String) {
            self.storage = []
            self.key = key
        }

        func prepare(query: inout DatabaseQuery) {
            // we can assume query.entity since eager loading
            // is only allowed on the base entity
            query.joins.append(.model(
                foreign: .field(path: [P.key(for: \._$id)], entity: P.entity, alias: nil),
                local: .field(path: [self.key], entity: query.entity, alias: nil),
                method: .inner
            ))
            query.fields += P().fields.map { (_, field) in
                return .field(
                    path: [field.key],
                    entity: P.entity,
                    alias: P.entity + "_" + field.key
                )
            }
        }

        func run(models: [AnyModel], on database: Database) -> EventLoopFuture<Void> {
            do {
                self.storage = try models.map { child in
                    return try child.joined(P.self)
                }
                return database.eventLoop.makeSucceededFuture(())
            } catch {
                return database.eventLoop.makeFailedFuture(error)
            }
        }

        func get(id: P.IDValue) throws -> P? {
            return self.storage.filter { parent in
                return parent.id == id
            }.first
        }
    }
}
