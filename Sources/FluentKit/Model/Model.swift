public protocol AnyModel {
    static var entity: String { get }
    static var id: String { get }
}

public protocol Model: AnyModel {
    static var shared: Self { get }
    associatedtype ID: Codable, Hashable
    var id: Field<ID?> { get }
    // MARK: Lifecycle

    func willCreate(_ row: Row<Self>, on database: Database) -> EventLoopFuture<Void>
    func didCreate(_ row: Row<Self>, on database: Database) -> EventLoopFuture<Void>

    func willUpdate(_ row: Row<Self>, on database: Database) -> EventLoopFuture<Void>
    func didUpdate(_ row: Row<Self>, on database: Database) -> EventLoopFuture<Void>

    func willDelete(_ row: Row<Self>, on database: Database) -> EventLoopFuture<Void>
    func didDelete(_ row: Row<Self>, on database: Database) -> EventLoopFuture<Void>

    func willRestore(_ row: Row<Self>, on database: Database) -> EventLoopFuture<Void>
    func didRestore(_ row: Row<Self>, on database: Database) -> EventLoopFuture<Void>

    func willSoftDelete(_ row: Row<Self>, on database: Database) -> EventLoopFuture<Void>
    func didSoftDelete(_ row: Row<Self>, on database: Database) -> EventLoopFuture<Void>
}

extension AnyModel {
    public static var entity: String {
        return "\(Self.self)"
    }
}

extension Model {
    public static func find(_ id: Self.ID?, on database: Database) -> EventLoopFuture<Row<Self>?> {
        guard let id = id else {
            return database.eventLoop.makeSucceededFuture(nil)
        }
        return Self.query(on: database).filter(\.id == id).first()
    }

    public static var id: String {
        return self.shared.id.name
    }
}

extension Model {
    public func willCreate(_ row: Row<Self>, on database: Database) -> EventLoopFuture<Void> {
        return database.eventLoop.makeSucceededFuture(())
    }
    public func didCreate(_ row: Row<Self>, on database: Database) -> EventLoopFuture<Void> {
        return database.eventLoop.makeSucceededFuture(())
    }

    public func willUpdate(_ row: Row<Self>, on database: Database) -> EventLoopFuture<Void> {
        return database.eventLoop.makeSucceededFuture(())
    }
    public func didUpdate(_ row: Row<Self>, on database: Database) -> EventLoopFuture<Void> {
        return database.eventLoop.makeSucceededFuture(())
    }

    public func willDelete(_ row: Row<Self>, on database: Database) -> EventLoopFuture<Void> {
        return database.eventLoop.makeSucceededFuture(())
    }
    public func didDelete(_ row: Row<Self>, on database: Database) -> EventLoopFuture<Void> {
        return database.eventLoop.makeSucceededFuture(())
    }

    public func willRestore(_ row: Row<Self>, on database: Database) -> EventLoopFuture<Void> {
        return database.eventLoop.makeSucceededFuture(())
    }
    public func didRestore(_ row: Row<Self>, on database: Database) -> EventLoopFuture<Void> {
        return database.eventLoop.makeSucceededFuture(())
    }

    public func willSoftDelete(_ row: Row<Self>, on database: Database) -> EventLoopFuture<Void> {
        return database.eventLoop.makeSucceededFuture(())
    }
    public func didSoftDelete(_ row: Row<Self>, on database: Database) -> EventLoopFuture<Void> {
        return database.eventLoop.makeSucceededFuture(())
    }
}


extension Model {
    public static func row() -> Row<Self> {
        let new = Row<Self>()
        if let timestampable = Self.shared as? _AnyTimestampable {
            timestampable._initializeTimestampable(&new.storage.input)
        }
        if let softDeletable = Self.shared as? _AnySoftDeletable {
            softDeletable._initializeSoftDeletable(&new.storage.input)
        }
        return new
    }
}

extension Model {
    public static func query(on database: Database) -> QueryBuilder<Self> {
        return .init(database: database)
    }
}

extension Array {
    public func create<Model>(on database: Database) -> EventLoopFuture<Void>
        where Model: FluentKit.Model, Element == Row<Model>
    {
        let builder = Model.query(on: database)
        self.forEach { model in
            precondition(!model.exists)
            builder.set(model.storage.input)
        }
        builder.query.action = .create
        var it = self.makeIterator()
        return builder.run { created in
            let next = it.next()!
            next.storage.exists = true
        }
    }
}
