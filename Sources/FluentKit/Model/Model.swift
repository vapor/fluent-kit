public protocol Model: AnyModel {
    associatedtype IDValue: Codable, Hashable

    var id: IDValue? { get set }
}

extension Model {
    public static func key<Field>(for field: KeyPath<Self, Field>) -> FieldKey
        where Field: FieldRepresentable
    {
        return Self.init()[keyPath: field].field.key
    }

    public static func query(on database: Database) -> QueryBuilder<Self> {
        return .init(database: database)
    }

    public static func find(_ id: Self.IDValue?, on database: Database) -> EventLoopFuture<Self?> {
        guard let id = id else {
            return database.eventLoop.makeSucceededFuture(nil)
        }
        return Self.query(on: database)
            .filter(\._$id == id)
            .first()
    }

    /// Indicates whether the model has fields that have been set, but the model has not yet been saved to the database.
    public var hasChanges: Bool {
        return !self.input.isEmpty
    }

    public func requireID() throws -> IDValue {
        guard let id = self.id else {
            throw FluentError.idRequired
        }
        return id
    }

    // MARK: Internal

    var _$id: ID<IDValue> {
        self.anyID as! ID<IDValue>
    }
}
