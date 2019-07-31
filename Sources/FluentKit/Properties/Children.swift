@propertyWrapper
public final class Children<P, C>: AnyProperty, AnyEagerLoadable
    where P: Model, C: Model
{
    // MARK: ID

    let foreignIDName: String
    private var eagerLoadedValue: [C]?
    private var idValue: P.ID?

    // MARK: Wrapper

    public init(_ parent: KeyPath<C, Parent<P>>) {
        self.foreignIDName = C.key(for: parent)
    }

    public var wrappedValue: [C] {
        get { fatalError("Use $ prefix to access") }
        set { fatalError("Use $ prefix to access") }
    }

    public var projectedValue: Children<P, C> {
        return self
    }


    // MARK: Query

    public func query(on database: Database) throws -> QueryBuilder<C> {
        guard let id = self.idValue else {
            fatalError("Cannot query children relation from unsaved model.")
        }
        return C.query(on: database)
            .filter(self.foreignIDName, .equal, id)
    }

    // MARK: Property

    func output(from output: DatabaseOutput, label: String) throws {
        let key = P.key(for: \.idField)
        if output.contains(field: key) {
            self.idValue = try output.decode(field: key, as: P.ID.self)
        }
    }

    // MARK: Codable

    func encode(to encoder: inout ModelEncoder, label: String) throws {
        if let rows = self.eagerLoadedValue {
            try encoder.encode(rows, forKey: label)
        }
    }
    
    func decode(from decoder: ModelDecoder, label: String) throws {
        // don't decode
    }

    // MARK: Eager Load

    public func eagerLoaded() throws -> [C] {
        guard let rows = self.eagerLoadedValue else {
            throw FluentError.missingEagerLoad(name: C.entity.self)
        }
        return rows
    }

    func eagerLoad(from eagerLoads: EagerLoads, label: String) throws {
        guard let request = eagerLoads.requests[label] else {
            return
        }
        if let subquery = request as? SubqueryEagerLoad {
            self.eagerLoadedValue = try subquery.get(id: self.idValue!)
        } else {
            fatalError("unsupported eagerload request: \(request)")
        }
    }

    func eagerLoad(to eagerLoads: EagerLoads, method: EagerLoadMethod, label: String) {
        switch method {
        case .subquery:
            eagerLoads.requests[label] = SubqueryEagerLoad(self.foreignIDName)
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

        func prepare(query: inout DatabaseQuery) {
            // do nothing
        }

        func run(models: [AnyModel], on database: Database) -> EventLoopFuture<Void> {
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
                return try child.anyIDField.cachedOutput!.decode(
                    field: self.foreignIDName, as: P.ID.self
                ) == id
            }
        }
    }
}


