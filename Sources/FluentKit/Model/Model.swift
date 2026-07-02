import NIOCore

public protocol Model: AnyModel {
    associatedtype IDValue: Codable, Hashable, Sendable
    var id: IDValue? { get set }
}

extension Model {
    public static func query(on database: any Database) -> QueryBuilder<Self> {
        .init(database: database)
    }

    public static func find(
        _ id: Self.IDValue?,
        on database: any Database
    ) -> EventLoopFuture<Self?> {
        database.eventLoop.makeFutureWithTask {
            try await self.find(id, on: database)
        }
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
    /// > Note: Adding this property to ``Model`` rather than making the ``AnyID`` protocol
    /// > and ``anyID`` property public was chosen because implementing a new conformance for
    /// > ``AnyID`` can not be done correctly from outside FluentKit; it would be mostly useless
    /// > and potentially confusing public API surface.
    public var _$idExists: Bool {
        get { self.anyID.exists }
        set { self.anyID.exists = newValue }
    }

    public var _$id: ID<IDValue> {
        self.anyID as! ID<IDValue>
    }

    /// The database ``FieldKey``(s) which make up this model's identifier.
    ///
    /// Returns a single key for models declared with `@ID`, or the complete set of composite
    /// keys for models declared with `@CompositeID`. Like ``_$idExists``, this works for both
    /// cases, whereas ``_$id`` traps when applied to a model using `@CompositeID`.
    ///
    /// > Note: This accessor exists for the same reason as ``_$idExists``: to avoid making the
    /// > ``AnyID`` protocol and ``anyID`` property public, which can not be usefully conformed
    /// > to from outside FluentKit.
    public var _$idKeys: [FieldKey] {
        self.anyID.keys
    }
}
