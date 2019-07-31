public protocol AnyModel: class, CustomStringConvertible, Codable {
    static var name: String { get }
    static var entity: String { get }
    init()
}

public protocol Model: AnyModel {
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

extension AnyModel {
    // MARK: Codable

    public init(from decoder: Decoder) throws {
        let decoder = try ModelDecoder(decoder: decoder)
        self.init()
        try self.properties.forEach { try $1.decode(from: decoder, label: $0) }
    }

    public func encode(to encoder: Encoder) throws {
        var encoder = ModelEncoder(encoder: encoder)
        try self.properties.forEach { try $1.encode(to: &encoder, label: $0) }
    }
}

extension Model {
    static func key<Field>(for field: KeyPath<Self, Field>) -> String
        where Field: AnyField
    {
        let ref = Self.init()
        return ref.key(for: ref[keyPath: field])
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

    func key(for field: AnyField) -> String {
        return field.key(label: self.label(for: field))
    }

    var input: [String: DatabaseQuery.Value] {
        var input: [String: DatabaseQuery.Value] = [:]
        for (label, field) in self.fields {
            input[field.key(label: label)] = field.input()
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
        if let o = self.anyIDField.cachedOutput {
            output = o.description
        } else {
            output = "[:]"
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
    func output(from output: DatabaseOutput) throws {
        try self.properties.forEach { (label, property) in
            try property.output(from: output, label: label)
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
        guard let output = self.anyIDField.cachedOutput else {
            fatalError("Can only access joined models using models fetched from database.")
        }
        let joined = Joined()
        try joined.output(from: output.prefixed(by: Joined.entity + "_"))
        return joined
    }

    var anyIDField: AnyField {
        guard let id = Mirror(reflecting: self).descendant("_id") else {
            fatalError("id property must be declared using @ID")
        }
        return id as! AnyField
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
        if self.name.hasSuffix("y") {
            return self.name.dropLast(1) + "ies"
        } else {
            return self.name + "s"
        }
    }
}

extension Model {
    public static func schema(on database: Database) -> SchemaBuilder<Self> {
        return .init(database: database)
    }

    public static func query(on database: Database) -> QueryBuilder<Self> {
        return .init(database: database)
    }

    public static func find(_ id: Self.ID?, on database: Database) -> EventLoopFuture<Self?> {
        guard let id = id else {
            return database.eventLoop.makeSucceededFuture(nil)
        }
        return Self.query(on: database)
            .filter(self.init().idField.key(label: "id"), .equal, id)
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
