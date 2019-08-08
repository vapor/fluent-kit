@propertyWrapper
public final class Parent<P>: AnyField, AnyEagerLoadable
    where P: Model
{
    // MARK: ID

    public let field: Field<P.ID>
    private var cachedLabel: String?
    private var eagerLoadedValue: P?

    public var id: P.ID {
        get {
            return self.field.wrappedValue
        }
        set {
            self.field.wrappedValue = newValue
        }
    }

    // MARK: Wrapper

    public var wrappedValue: P {
        get { fatalError("use $ prefix to access") }
        set { fatalError("use $ prefix to access") }
    }

    public var projectedValue: Parent<P> {
        return self
    }

    public init() {
        self.field = .init()
    }

    public init(_ key: String) {
        self.field = .init(key)
    }

    // MARK: Query

    public func query(on database: Database) -> QueryBuilder<P> {
        let name: String

        if let key = self.field.key {
            name = key
        } else if let label = self.cachedLabel {
            name = label.convertedToSnakeCase() + "_id"
        } else {
            fatalError("Cannot query parent relation before saving model")
        }

        return P.query(on: database)
            .filter(name, .equal, self.id)
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

    func key(label: String) -> String {
        return self.field.key(label: label + "_id")
    }

    var cachedOutput: DatabaseOutput? {
        return self.field.cachedOutput
    }

    var exists: Bool {
        get {
            return self.field.exists
        }
        set {
            self.field.exists = newValue
        }
    }

    var inputValue: DatabaseQuery.Value? {
        get {
            return self.field.inputValue
        }
        set {
            self.field.inputValue = newValue
        }
    }

    // MARK: Property

    func output(from output: DatabaseOutput, label: String) throws {
        try self.field.output(from: output, label: self.key(label: label))
    }

    // MARK: Eager Loadable

    func eagerLoad(from eagerLoads: EagerLoads, label: String) throws {
        guard let request = eagerLoads.requests[label] else {
            return
        }

        if let join = request as? JoinEagerLoad {
            self.eagerLoadedValue = try join.get(id: self.field.wrappedValue)
        } else if let subquery = request as? SubqueryEagerLoad {
            self.eagerLoadedValue = try subquery.get(id: self.field.wrappedValue)
        } else {
            fatalError("unsupported eagerload request: \(request)")
        }
    }

    func eagerLoad(to eagerLoads: EagerLoads, method: EagerLoadMethod, label: String) {
        switch method {
        case .subquery:
            eagerLoads.requests[label] = SubqueryEagerLoad(key: self.key(label: label))
        case .join:
            eagerLoads.requests[label] = JoinEagerLoad(key: self.key(label: label))
        }
    }
    
    func encode(to encoder: inout ModelEncoder, label: String) throws {
        if let parent = self.eagerLoadedValue {
            try encoder.encode(parent, forKey: label)
        } else {
            try encoder.encode([
                P.key(for: \._$id): self.id
            ], forKey: label)
        }
    }
    
    func decode(from decoder: ModelDecoder, label: String) throws {
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
            let ids: [P.ID] = models
                .map { try! $0.anyIDField.cachedOutput!.decode(field: self.key, as: P.ID.self) }

            let uniqueIDs = Array(Set(ids))
            return P.query(on: database)
                .filter(P.key(for: \._$id), in: uniqueIDs)
                .all()
                .map { self.storage = $0 }
        }

        func get(id: P.ID) throws -> P? {
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
            query.fields += P().fields.map { (label, field) in
                return .field(
                    path: [field.key(label: label)],
                    entity: P.entity,
                    alias: P.entity + "_" + field.key(label: label)
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

        func get(id: P.ID) throws -> P? {
            return self.storage.filter { parent in
                return parent.id == id
            }.first
        }
    }
}
