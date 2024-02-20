import NIOCore

public protocol Model: AnyModel {
    associatedtype IDValue: Codable, Hashable
    var id: IDValue? { get set }
}

extension Model {
    public static func query(on database: Database) -> QueryBuilder<Self> {
        .init(database: database)
    }

    public static func find(
        _ id: Self.IDValue?,
        on database: Database
    ) -> EventLoopFuture<Self?> {
        guard let id = id else {
            return database.eventLoop.makeSucceededFuture(nil)
        }
        return Self.query(on: database)
            .filter(id: id)
            .first()
    }

    public func requireID() throws -> IDValue {
        guard let id = self.id else {
            throw FluentError.idRequired
        }
        return id
    }
    
    /// Replaces the existing common usage of `model._$id.exists`, which indicates whether any
    /// particular generic model has a non-`nil` ID that was loaded from a database query (or
    /// was overridden to allow Fluent to assume as such without having to check first). This
    /// version works for models which use `@CompositeID()`. It would not be necessary if
    /// support existed for property wrappers in protocols.
    ///
    /// - Note: Adding this property to ``Model`` rather than making the ``AnyID`` protocol
    ///   and ``anyID`` property public was chosen because implementing a new conformance for
    ///   ``AnyID`` can not be done correctly from outside FluentKit; it would be mostly useless
    ///   and potentially confusing public API surface.
    public var _$idExists: Bool {
        get { self.anyID.exists }
        set { self.anyID.exists = newValue }
    }

    public var _$id: ID<IDValue> {
        self.anyID as! ID<IDValue>
    }
}
