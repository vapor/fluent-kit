public protocol AnyModel: class {
    static var name: String { get }
    static var entity: String { get }
}

public protocol Model: AnyModel, Codable {
    associatedtype ID: Codable, Hashable

    var id: ID? { get set }
    init()

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
        for property in self.properties {
            try property.decode(from: decoder)
        }
    }

    public func encode(to encoder: Encoder) throws {
        var encoder = ModelEncoder(encoder: encoder)
        for property in self.properties {
            try property.encode(to: &encoder)
        }
    }

    // MARK: Joined

    public func joined<Joined>(_ model: Joined.Type) throws -> Joined
        where Joined: FluentKit.Model
    {
        return try Joined(storage: DefaultStorage(
            output: self.storage!.output!.prefixed(by: Joined.entity + "_"),
            eagerLoads: [:],
            exists: true
        ))
    }

    // MARK: Description

    public var description: String {
        let input: String
        if self.input.isEmpty {
            input = "nil"
        } else {
            input = self.input.description
        }
        let output: String
        if let o = self.storage?.output {
            output = o.description
        } else {
            output = "nil"
        }
        return "\(Self.self)(input: \(input), output: \(output))"
    }
}

extension Model {
    static var _reference: Self {
        return .init()
    }

    var _idField: FluentKit.ID<Self.ID?> {
        guard let id = Mirror(reflecting: self).descendant("$$id") else {
            fatalError("id property must be declared using @ID")
        }
        return id as! FluentKit.ID<Self.ID?>
    }
}

extension Model {
    var exists: Bool {
        return self.storage?.exists ?? false
    }

    var storage: Storage? {
        get {
            return self._idField.storage
        }
        set {
            self._idField.storage = newValue
        }
    }

    internal var input: [String: DatabaseQuery.Value] {
        var input = [String: DatabaseQuery.Value]()
        for field in self.fields {
            input[field.name] = field.input
        }
        return input
    }

    internal init(storage: Storage) throws {
        self.init()
        for property in self.properties {
            try property.load(from: storage)
        }
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
            .filter(self._reference._idField.name, .equal, id)
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
            precondition(!model.exists)
            builder.set(model.input)
        }
        builder.query.action = .create
        var it = self.makeIterator()
        return builder.run { created in
            let next = it.next()!
            next.storage!.exists = true
        }
    }
}
