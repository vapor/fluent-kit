public protocol AnyModel: class, CustomStringConvertible, Codable {
    static var schema: String { get }
    init()
}

public protocol Model: AnyModel {
    associatedtype IDValue: Codable, Hashable

    var id: IDValue? { get set }

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

extension AnyModel {
    // MARK: Codable

    public init(from decoder: Decoder) throws {
        self.init()
        let container = try decoder.container(keyedBy: _ModelCodingKey.self)
        try self.properties.forEach { label, property in
            let decoder = try container.superDecoder(forKey: .string(label))
            try property.decode(from: decoder)
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: _ModelCodingKey.self)
        try self.properties.forEach { label, property in
            let encoder = container.superEncoder(forKey: .string(label))
            try property.encode(to: encoder)
        }
    }
}

extension Model {
    static func key<Field>(for field: KeyPath<Self, Field>) -> String
        where Field: Filterable
    {
        return Self.init()[keyPath: field].key
    }
}

extension AnyModel {
    // MARK: Description

    func label(for property: AnyProperty) -> String {
        for (label, p) in self.properties {
            if property === p {
                return label
            }
        }
        fatalError("Property not found on model.")
    }

    var input: [String: DatabaseQuery.Value] {
        var input: [String: DatabaseQuery.Value] = [:]
        for (_, field) in self.fields {
            input[field.key] = field.inputValue
        }
        return input
    }

    public var description: String {
        let input: String
        if self.input.isEmpty {
            input = "nil"
        } else {
            input = self.input.description
        }

        let output: String
        if let o = self.anyID.cachedOutput {
            output = o.description
        } else {
            output = "[:]"
        }

        return "\(Self.self)(input: \(input), output: \(output))"
    }
}

extension Model {
    var _$id: ID<IDValue> {
        self.anyID as! ID<IDValue>
    }

    @available(*, deprecated, message: "use init")
    static var reference: Self {
        return self.init()
    }
}

extension AnyModel {
    func output(from output: DatabaseOutput) throws {
        try self.properties.forEach { (_, property) in
            try property.output(from: output)
        }
    }

    func eagerLoad(from eagerLoads: EagerLoads) throws {
        try self.eagerLoadables.forEach { (label, eagerLoadable) in
            try eagerLoadable.eagerLoad(from: eagerLoads, label: label)
        }

    }

    // MARK: Joined

    public func joined<Joined>(_ model: Joined.Type) throws -> Joined
        where Joined: FluentKit.Model
    {
        guard let output = self.anyID.cachedOutput else {
            fatalError("Can only access joined models using models fetched from database.")
        }
        let joined = Joined()
        try joined.output(from: output.prefixed(by: Joined.schema + "_"))
        return joined
    }

    var anyID: AnyID {
        guard let id = Mirror(reflecting: self).descendant("_id") else {
            fatalError("id property must be declared using @ID")
        }
        return id as! AnyID
    }
}

extension Model {
    public func requireID() throws -> IDValue {
        guard let id = self.id else {
            throw FluentError.idRequired
        }
        return id
    }
}

extension Model {
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
