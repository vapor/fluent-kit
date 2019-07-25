public protocol AnyModel: class, CustomStringConvertible {
    static var name: String { get }
    static var entity: String { get }
    init()
}

extension AnyModel {
    public func initialize() {
        let storage = Storage()
        Mirror(reflecting: self).children.forEach { child in
            if let property = child.value as? AnyProperty, let label = child.label {
                // remove underscore
                property.label = .init(label.dropFirst())
                // set root model type
                property.modelType = Self.self
                // set shared storage
                property._storage = storage
            }
        }
    }
}

public protocol Model: AnyModel, Codable {
    associatedtype ID: Codable, Hashable

    var id: ID? { get set }

    // MARK: Lifecycle

    func willCreate(on database: Database) -> EventLoopFuture<Void>
    func didCreate(on database: Database) -> EventLoopFuture<Void>

    func willUpdate(on database: Database) -> EventLoopFuture<Void>
    func didUpdate(on database: Database) -> EventLoopFuture<Void>

    func willDelete(on database: Database) -> EventLoopFuture<Void>
    func didDelete(on database: Database) -> EventLoopFuture<Void>

    func willRestore(on database: Database) -> EventLoopFuture<Void>
    func didRestore(on database: Database) -> EventLoopFuture<Void>

    func willSoftDelete(on database: Database) -> EventLoopFuture<Void>
    func didSoftDelete(on database: Database) -> EventLoopFuture<Void>
}

extension Model {
    // MARK: Codable

    public init(from decoder: Decoder) throws {
        let decoder = try ModelDecoder(decoder: decoder)
        self.init()
        try self.properties.forEach { try $0.decode(from: decoder) }
    }

    public func encode(to encoder: Encoder) throws {
        var encoder = ModelEncoder(encoder: encoder)
        try self.properties.forEach { try $0.encode(to: &encoder) }
    }
}

extension AnyModel {
    // MARK: Description

    public var description: String {
        let input: String
        if self.storage.input.isEmpty {
            input = "nil"
        } else {
            input = self.storage.input.description
        }
        let output: String
        if let o = self.storage.output {
            output = o.description
        } else {
            output = "nil"
        }
        return "\(Self.self)(input: \(input), output: \(output))"
    }
}

extension Model {
    var idField: Field<Self.ID?> {
        self.anyIDField as! Field<Self.ID?>
    }

    @available(*, deprecated, message: "use init")
    static var reference: Self {
        return self.init()
    }
}

extension AnyModel {
    // MARK: Joined

    public func joined<Joined>(_ model: Joined.Type) throws -> Joined
        where Joined: FluentKit.Model
    {
        let joined = Joined()
        joined.storage.output = self.storage.output?.prefixed(by: Joined.entity + "_")
        joined.storage.exists = true
        return joined
    }

    var anyIDField: AnyField {
        guard let id = Mirror(reflecting: self).descendant("_id") else {
            fatalError("id property must be declared using @ID")
        }
        return id as! AnyField
    }

    var storage: Storage {
        return self.anyIDField.storage
    }
}

extension Model {
    public func requireID() throws -> ID {
        guard let id = self.id else {
            throw FluentError.idRequired
        }
        return id
    }
}

extension AnyModel {
    public static var name: String {
        return "\(Self.self)".lowercased()
    }

    public static var entity: String {
        return self.name + "s"
    }
}

extension Model {
    public static func find(_ id: Self.ID?, on database: Database) -> EventLoopFuture<Self?> {
        guard let id = id else {
            return database.eventLoop.makeSucceededFuture(nil)
        }
        return Self.query(on: database)
            .filter(self.reference.idField.name, .equal, id)
            .first()
    }
}

extension Model {
    public func willCreate(on database: Database) -> EventLoopFuture<Void> {
        return database.eventLoop.makeSucceededFuture(())
    }
    public func didCreate(on database: Database) -> EventLoopFuture<Void> {
        return database.eventLoop.makeSucceededFuture(())
    }

    public func willUpdate(on database: Database) -> EventLoopFuture<Void> {
        return database.eventLoop.makeSucceededFuture(())
    }
    public func didUpdate(on database: Database) -> EventLoopFuture<Void> {
        return database.eventLoop.makeSucceededFuture(())
    }

    public func willDelete(on database: Database) -> EventLoopFuture<Void> {
        return database.eventLoop.makeSucceededFuture(())
    }
    public func didDelete(on database: Database) -> EventLoopFuture<Void> {
        return database.eventLoop.makeSucceededFuture(())
    }

    public func willRestore(on database: Database) -> EventLoopFuture<Void> {
        return database.eventLoop.makeSucceededFuture(())
    }
    public func didRestore(on database: Database) -> EventLoopFuture<Void> {
        return database.eventLoop.makeSucceededFuture(())
    }

    public func willSoftDelete(on database: Database) -> EventLoopFuture<Void> {
        return database.eventLoop.makeSucceededFuture(())
    }
    public func didSoftDelete(on database: Database) -> EventLoopFuture<Void> {
        return database.eventLoop.makeSucceededFuture(())
    }
}

extension Model {
    public static func query(on database: Database) -> QueryBuilder<Self> {
        return .init(database: database)
    }
}

extension Array where Element: FluentKit.Model {
    public func create(on database: Database) -> EventLoopFuture<Void> {
        let builder = Element.query(on: database)
        self.forEach { model in
            precondition(!model.storage.exists)
        }
        builder.set(self.map { $0.storage.input })
        builder.query.action = .create
        var it = self.makeIterator()
        return builder.run { created in
            let next = it.next()!
            next.storage.exists = true
        }
    }
}
