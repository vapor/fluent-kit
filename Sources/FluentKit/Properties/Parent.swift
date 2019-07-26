@propertyWrapper
public final class Parent<P>: AnyField
    where P: Model
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

    public var wrappedValue: P {
        get { fatalError("use $ prefix to access") }
        set { fatalError("use $ prefix to access") }
    }

    public var projectedValue: Parent<P> {
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
            .filter(P().idField.name, .equal, self.id)
    }


    public func get(on database: Database) -> EventLoopFuture<P> {
        return self.query(on: database).first().map { parent in
            guard let parent = parent else {
                fatalError("no parent found")
            }
            return parent
        }
    }

    // MARK: Property

    var label: String? {
        didSet {
            if let label = self.label {
                self.idField.label = label + "_id"
            } else {
                self.idField.label = nil
            }
        }
    }

    // MARK: Field

    var name: String {
        return self.idField.name
    }

    var type: Any.Type {
        return self.idField.type
    }

    var nameOverride: String? {
        return self.idField.nameOverride
    }

    // MARK: Codable
    
    func encode(to encoder: inout ModelEncoder) throws {
        if let parent = try self.eagerLoadedValue() {
            try encoder.encode(parent, forKey: self.label!)
        } else {
            try encoder.encode([
                P().idField.name: self.id
            ], forKey: self.label!)
        }
    }
    
    func decode(from decoder: ModelDecoder) throws {
        #warning("TODO: allow for nested decoding")
        // self.id = try decoder.decode(<#T##value: Decodable.Protocol##Decodable.Protocol#>, forKey: <#T##String#>)
    }

    // MARK: Eager Load

    public func eagerLoaded() throws -> P {
        guard let eagerLoaded = try self.eagerLoadedValue() else {
            throw FluentError.missingEagerLoad(name: P.entity.self)
        }
        return eagerLoaded
    }

    private func eagerLoadedValue() throws -> P? {
        guard let request = self.storage.eagerLoadStorage.requests[P.entity] else {
            return nil
        }

        if let join = request as? JoinEagerLoad {
            return try join.get(id: self.idField.wrappedValue)
        } else if let subquery = request as? SubqueryEagerLoad {
            return try subquery.get(id: self.idField.wrappedValue)
        } else {
            fatalError("unsupported eagerload request: \(request)")
        }
    }

    func addEagerLoadRequest(method: EagerLoadMethod, to storage: EagerLoadStorage) {
        switch method {
        case .subquery:
            storage.requests[P.entity] = SubqueryEagerLoad(self.idField)
        case .join:
            storage.requests[P.entity] = JoinEagerLoad(self.idField)
        }
    }

    private final class SubqueryEagerLoad: EagerLoadRequest {
        var storage: [P]
        let idField: Field<P.ID>

        var description: String {
            return "\(self.idField.name): \(self.storage)"
        }

        init(_ idField: Field<P.ID>) {
            self.storage = []
            self.idField = idField
        }

        func prepare(_ query: inout DatabaseQuery) {
            // no preparation needed
        }

        func run(_ models: [Any], on database: Database) -> EventLoopFuture<Void> {
            let ids: [P.ID] = models
                .map { $0 as! AnyModel }
                .map { try! $0.storage.output!.decode(field: self.idField.name, as: P.ID.self) }

            let uniqueIDs = Array(Set(ids))
            return P.query(on: database)
                .filter(P().idField.name, in: uniqueIDs)
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

        var description: String {
            return "\(self.idField.name): \(self.parents)"
        }

        init(_ idField: Field<P.ID>) {
            self.parents = [:]
            self.idField = idField
        }

        func prepare(_ query: inout DatabaseQuery) {
            query.joins.append(.model(
                foreign: .field(path: [P().idField.name], entity: P.entity, alias: nil),
                local: .field(path: [self.idField.name], entity: self.idField.modelType!.entity, alias: nil),
                method: .inner
            ))
            query.fields += P().fields.map { field in
                return .field(
                    path: [field.name],
                    entity: P.entity,
                    alias: P.entity + "_" + field.name
                )
            }
        }

        func run(_ models: [Any], on database: Database) -> EventLoopFuture<Void> {
            do {
                var res: [P.ID: P] = [:]
                try models.map { $0 as! AnyModel }.forEach { child in
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
