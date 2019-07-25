@propertyWrapper
public final class Children<P, C>: AnyProperty
    where P: Model, C: Model
{
    // MARK: ID

    let idField: Field<P.ID>

    var parentID: P.ID?

    var modelType: AnyModel.Type?

    // MARK: Wrapper

    public init(_ keyPath: KeyPath<C, Parent<P>>) {
        self.idField = C.reference[keyPath: keyPath].idField
    }

    public var wrappedValue: [C] {
        get { fatalError("Use $ prefix to access") }
        set { fatalError("Use $ prefix to access") }
    }

    public var projectedValue: Children<P, C> {
        return self
    }

    // MARK: Query

    public func query(on database: Database) -> QueryBuilder<C> {
        guard let id = self.parentID else {
            fatalError("Cannot form children query without model id")
        }
        return C.query(on: database)
            .filter(self.idField.name, .equal, id)
    }

    // MARK: Property

    var label: String?

    func setOutput(from storage: Storage) throws {
        self.parentID = try storage.output!.decode(field: P.reference.idField.name, as: P.ID.self)
        try self.setEagerLoaded(from: storage)
    }

    // MARK: Codable

    func encode(to encoder: inout ModelEncoder) throws {
        if let rows = try self.eagerLoadedValue() {
            try encoder.encode(rows, forKey: self.label!)
        }
    }
    
    func decode(from decoder: ModelDecoder) throws {
        // don't decode
    }

    // MARK: Eager Load

    private var eagerLoadRequest: EagerLoadRequest?

    private func eagerLoadedValue() throws -> [C]? {
        guard let request = self.eagerLoadRequest else {
            return nil
        }
        if let subquery = request as? SubqueryEagerLoad {
            return try subquery.get(id: self.parentID!)
        } else {
            fatalError("unsupported eagerload request: \(request)")
        }
    }

    public func eagerLoaded() throws -> [C] {
        guard let rows = try self.eagerLoadedValue() else {
            throw FluentError.missingEagerLoad(name: C.entity.self)
        }
        return rows
    }

    func addEagerLoadRequest(method: EagerLoadMethod, to storage: EagerLoadStorage) {
        switch method {
        case .subquery:
            storage.requests[C.entity] = SubqueryEagerLoad(self.idField)
        case .join:
            fatalError("Eager loading children using join is not yet supported")
        }
    }

    func setEagerLoaded(from storage: Storage) throws {
        if let eagerLoad = storage.eagerLoadStorage.requests[C.entity] {
            self.eagerLoadRequest = eagerLoad
        }
    }

    private final class SubqueryEagerLoad: EagerLoadRequest {
        var storage: [C]
        let idField: Field<P.ID>

        var description: String {
            return "\(self.idField.name): \(self.storage)"
        }

        init(_ idField: Field<P.ID>) {
            self.storage = []
            self.idField = idField
        }

        func prepare(_ query: inout DatabaseQuery) {
            // do nothing
        }

        func run(_ models: [Any], on database: Database) -> EventLoopFuture<Void> {
            let ids: [P.ID] = models
                .map { $0 as! P }
                .map { $0.id! }
            let uniqueIDs = Array(Set(ids))
            return C.query(on: database)
                .filter(
                    DatabaseQuery.Filter.basic(
                        .field(path: [self.idField.name], entity: self.idField.modelType!.entity, alias: nil),
                        .subset(inverse: false),
                        .array(uniqueIDs.map { .bind($0) })
                    )
                )
                .all()
                .map { (children: [C]) -> Void in
                    self.storage = children
                }
        }

        func get(id: P.ID) throws -> [C] {
            return try self.storage.filter { child in
                return try child.storage!.output!.decode(
                    field: self.idField.name, as: P.ID.self
                ) == id
            }
        }
    }
}


