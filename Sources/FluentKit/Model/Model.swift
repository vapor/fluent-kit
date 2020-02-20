public protocol Model: AnyModel {
    associatedtype IDValue: Codable, Hashable

    var id: IDValue? { get set }
}

public protocol Fields: class, Codable {
    init()
}

extension Fields {
    public static func path<Field>(for field: KeyPath<Self, Field>) -> [FieldKey]
        where Field: FieldRepresentable
    {
         Self.init()[keyPath: field].path
    }
}

extension Model {

    public static func query(on database: Database) -> QueryBuilder<Self> {
        .init(database: database)
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
        return !self.input.fields.isEmpty
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
