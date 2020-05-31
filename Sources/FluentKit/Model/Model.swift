public protocol Model: AnyModel {
    associatedtype IDValue: Codable, Hashable
    var id: IDValue? { get set }
}

extension Model {
    public static func query(on database: Database) -> QueryBuilder<Self> {
        .init(database: database)
    }
    
    public static func query(on database: Database,
                             in namespace: [String] = []) -> QueryBuilder<Self> {
        let query = QueryBuilder<Self>(database: database, namespace: namespace)
        if let query = query { return query }
        fatalError("Table aliasing must be enabled for namespaced tables")
    }

    public static func find(
        _ id: Self.IDValue?,
        on database: Database
    ) -> EventLoopFuture<Self?> {
        guard let id = id else {
            return database.eventLoop.makeSucceededFuture(nil)
        }
        return Self.query(on: database)
            .filter(\._$id == id)
            .first()
    }

    public func requireID() throws -> IDValue {
        guard let id = self.id else {
            throw FluentError.idRequired
        }
        return id
    }

    public var _$id: ID<IDValue> {
        self.anyID as! ID<IDValue>
    }
}
