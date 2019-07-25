@propertyWrapper
public final class Children<P, C>: AnyProperty
    where P: Model, C: Model
{
    // MARK: ID

    let foreignIDName: String
    var modelType: AnyModel.Type?
    var _storage: Storage?

    // MARK: Wrapper

    public init(_ parent: KeyPath<C, Parent<P>>) {
        self.foreignIDName = C()[keyPath: parent].idField.name
    }

    public var wrappedValue: [C] {
        get { fatalError("Use $ prefix to access") }
        set { fatalError("Use $ prefix to access") }
    }

    public var projectedValue: Children<P, C> {
        return self
    }

    private var parentID: P.ID {
        return try! self.storage.output!.decode(field: P().idField.name, as: P.ID.self)
    }

    // MARK: Query

    public func query(on database: Database) -> QueryBuilder<C> {
        return C.query(on: database)
            .filter(self.foreignIDName, .equal, self.parentID)
    }

    // MARK: Property

    var label: String?

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

    private func eagerLoadedValue() throws -> [C]? {
        guard let request = self.storage.eagerLoadStorage.requests[C.entity] else {
            return nil
        }
        if let subquery = request as? SubqueryEagerLoad {
            return try subquery.get(id: self.parentID)
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
            storage.requests[C.entity] = SubqueryEagerLoad(self.foreignIDName)
        case .join:
            fatalError("Eager loading children using join is not yet supported")
        }
    }

    private final class SubqueryEagerLoad: EagerLoadRequest {
        var storage: [C]
        let foreignIDName: String

        var description: String {
            return "\(self.foreignIDName): \(self.storage)"
        }

        init(_ foreignIDName: String) {
            self.storage = []
            self.foreignIDName = foreignIDName
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
                        .field(path: [self.foreignIDName], entity: C.entity, alias: nil),
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
                return try child.storage.output!.decode(
                    field: self.foreignIDName, as: P.ID.self
                ) == id
            }
        }
    }
}


