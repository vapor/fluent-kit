@propertyWrapper
public final class Parent<C, P>: AnyField
    where P: Model, C: Model
{
    // MARK: ID

    let idField: Field<P.ID>

    public var id: P.ID {
        get {
            return self.idField.wrappedValue
        }
        set {
            self.idField.wrappedValue = newValue
        }
    }

    // MARK: Wrapper

    public var wrappedValue: C {
        fatalError("use $ prefix to access")
    }

    public var projectedValue: Parent<C, P> {
        return self
    }

    public init() {
        self.idField = .init()
    }

    public init(_ key: String) {
        self.idField = .init(key)
    }

    // MARK: Query

    public func query(on database: Database) -> QueryBuilder<P> {
        return P.query(on: database)
            .filter(P.reference.idField.name, .equal, self.id)
    }


    public func get(on database: Database) -> EventLoopFuture<P> {
        return self.query(on: database).first().map { parent in
            guard let parent = parent else {
                fatalError()
            }
            return parent
        }
    }

    // MARK: Property

    var label: String? {
        get {
            return self.idField.label
        }
        set {
            if let label = newValue {
                self.idField.label = label + "_id"
            } else {
                self.idField.label = nil
            }
        }
    }

    func setOutput(from storage: Storage) throws {
        try self.idField.setOutput(from: storage)
        try self.setEagerLoad(from: storage)
    }

    // MARK: Field

    var type: Any.Type {
        return self.idField.type
    }

    var nameOverride: String? {
        return self.idField.nameOverride
    }

    func setInput(to input: inout [String : DatabaseQuery.Value]) {
        self.idField.setInput(to: &input)
    }

    // MARK: Codable
    
    func encode(to encoder: inout ModelEncoder) throws {
        if let parent = self.eagerLoadedValue {
            try encoder.encode(parent, forKey: self.label!)
        } else {
            try encoder.encode([
                C.reference.idField.name: self.id
            ], forKey: self.label!)
        }
    }
    
    func decode(from decoder: ModelDecoder) throws {
        self.id = try decoder.decode(P.ID.self, forKey: self.label!)
    }

    // MARK: Eager Load

    var eagerLoadedValue: P?

    public var isEagerLoaded: Bool {
        return self.eagerLoadedValue != nil
    }

    public func eagerLoaded() throws -> P {
        guard let eagerLoaded = self.eagerLoadedValue else {
            throw FluentError.missingEagerLoad(name: C.entity.self)
        }
        return eagerLoaded
    }

    func addEagerLoadRequest(method: EagerLoadMethod, to storage: EagerLoadStorage) {
        switch method {
        case .subquery:
            storage.requests[P.entity] = SubqueryEagerLoad(self.idField)
        case .join:
            storage.requests[P.entity] = JoinEagerLoad(self.idField)
        }
    }

    func setEagerLoad(from storage: Storage) throws {
        if let eagerLoad = storage.eagerLoadStorage.requests[P.entity] {
            if let join = eagerLoad as? JoinEagerLoad {
                self.eagerLoadedValue = try join.get(id: self.idField.wrappedValue)
            }
            if let subquery = eagerLoad as? SubqueryEagerLoad {
                self.eagerLoadedValue = try subquery.get(id: self.idField.wrappedValue)
            }
        }
    }

    private final class SubqueryEagerLoad: EagerLoadRequest {
        var storage: [P]
        let idField: Field<P.ID>

        init(_ idField: Field<P.ID>) {
            self.storage = []
            self.idField = idField
        }

        func prepare(_ query: inout DatabaseQuery) {
            // no preparation needed
        }

        func run(_ models: [Any], on database: Database) -> EventLoopFuture<Void> {
            let ids: [P.ID] = models
                .map { $0 as! C }
                .map { try! $0.storage!.output!.decode(field: self.idField.name, as: P.ID.self) }

            let uniqueIDs = Array(Set(ids))
            return P.query(on: database)
                .filter(P.reference.idField.name, in: uniqueIDs)
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
        var parents: [P.ID: P]
        let idField: Field<P.ID>

        init(_ idField: Field<P.ID>) {
            self.parents = [:]
            self.idField = idField
        }

        func prepare(_ query: inout DatabaseQuery) {
            query.joins.append(.model(
                foreign: .field(path: [P.reference.idField.name], entity: P.entity, alias: nil),
                local: .field(path: [self.idField.name], entity: C.entity, alias: nil),
                method: .inner
            ))
        }

        func run(_ models: [Any], on database: Database) -> EventLoopFuture<Void> {
            do {
                var res: [P.ID: P] = [:]
                try models.map { $0 as! C }.forEach { child in
                    let parent = try child.joined(P.self)
                    try res[parent.requireID()] = parent
                }
                self.parents = res
                return database.eventLoop.makeSucceededFuture(())
            } catch {
                return database.eventLoop.makeFailedFuture(error)
            }
        }

        func get(id: P.ID) throws -> P? {
            return self.parents[id]
        }
    }
}
