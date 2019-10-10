public protocol AnyModel: class, CustomStringConvertible, Codable {
    static var schema: String { get }
    init()
}

public protocol ModelAlias {
    associatedtype Model: FluentKit.Model
    static var alias: String { get }
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
            let decoder = LazyDecoder { try container.superDecoder(forKey: .string(label)) }
            try property.decode(from: decoder)
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: _ModelCodingKey.self)
        try self.properties.forEach { label, property in
            let encoder = LazyEncoder { container.superEncoder(forKey: .string(label)) }
            try property.encode(to: encoder)
        }
    }
}

private final class LazyDecoder: Decoder {
    let factory: () throws -> Decoder
    var cached: Result<Decoder, Error>?
    
    var value: Result<Decoder, Error> {
        if let decoder = self.cached {
            return decoder
        } else {
            let decoder: Result<Decoder, Error>
            do {
                decoder = try .success(self.factory())
            } catch {
                decoder = .failure(error)
            }
            self.cached = decoder
            return decoder
        }
    }
    
    var codingPath: [CodingKey] {
        return (try? self.value.get().codingPath) ?? []
    }
    var userInfo: [CodingUserInfoKey : Any] {
        return (try? self.value.get().userInfo) ?? [:]
    }
    
    init(factory: @escaping () throws -> Decoder) {
        self.factory = factory
    }
    
    func container<Key>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key> where Key : CodingKey {
        return try self.value.get().container(keyedBy: Key.self)
    }
    
    func unkeyedContainer() throws -> UnkeyedDecodingContainer {
        return try self.value.get().unkeyedContainer()
    }
    
    func singleValueContainer() throws -> SingleValueDecodingContainer {
        return try self.value.get().singleValueContainer()
    }
    
}

private final class LazyEncoder: Encoder {
    let factory: () -> Encoder
    var cached: Encoder?
    var value: Encoder {
        if let encoder = self.cached {
            return encoder
        } else {
            let encoder = self.factory()
            self.cached = encoder
            return encoder
        }
    }
    
    var codingPath: [CodingKey] {
        return self.value.codingPath
    }
    var userInfo: [CodingUserInfoKey : Any] {
        return self.value.userInfo
    }
    
    init(factory: @escaping () -> Encoder) {
        self.factory = factory
    }
    
    func container<Key>(keyedBy type: Key.Type) -> KeyedEncodingContainer<Key> where Key : CodingKey {
        return self.value.container(keyedBy: Key.self)
    }
    
    func unkeyedContainer() -> UnkeyedEncodingContainer {
        return self.value.unkeyedContainer()
    }
    
    func singleValueContainer() -> SingleValueEncodingContainer {
        return self.value.singleValueContainer()
    }
}

extension Model {
    static func key<Field>(for field: KeyPath<Self, Field>) -> String
        where Field: FieldRepresentable
    {
        return Self.init()[keyPath: field].field.key
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
        var info: [InfoKey: CustomStringConvertible] = [:]

        if !self.input.isEmpty {
            info["input"] = self.input
        }

        if let output = self.anyID.cachedOutput {
            info["output"] = output
        }

        let eagerLoads: [String: CustomStringConvertible] = .init(uniqueKeysWithValues: self.eagerLoadables.compactMap { (name, eagerLoadable) in
            if let value = eagerLoadable.eagerLoadValueDescription {
                return (name, value)
            } else {
                return nil
            }
        })
        if !eagerLoads.isEmpty {
            info["eagerLoads"] = eagerLoads
        }

        return "\(Self.self)(\(info.debugDescription.dropFirst().dropLast()))"
    }
}

private struct InfoKey: ExpressibleByStringLiteral, Hashable, CustomStringConvertible {
    let value: String
    var description: String {
        return self.value
    }
    init(stringLiteral value: String) {
        self.value = value
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

    public func joined<Joined>(_ model: Joined.Type) throws -> Joined.Model
        where Joined: ModelAlias
    {
        guard let output = self.anyID.cachedOutput else {
            fatalError("Can only access joined models using models fetched from database.")
        }
        let joined = Joined.Model()
        try joined.output(from: output.prefixed(by: Joined.alias + "_"))
        return joined
    }


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
