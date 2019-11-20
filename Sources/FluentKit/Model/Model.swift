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
}

extension AnyModel {
    // MARK: Codable

    public init(from decoder: Decoder) throws {
        self.init()
        let container = try decoder.container(keyedBy: _ModelCodingKey.self)
        try self.properties.forEach { label, property in
            let decoder = ContainerDecoder(container: container, key: .string(label))
            try property.decode(from: decoder)
        }
    }

    public func encode(to encoder: Encoder) throws {
        let container = encoder.container(keyedBy: _ModelCodingKey.self)
        try self.properties.forEach { label, property in
            let encoder = ContainerEncoder(container: container, key: .string(label))
            try property.encode(to: encoder)
        }
    }
}

private struct ContainerDecoder: Decoder, SingleValueDecodingContainer {
    let container: KeyedDecodingContainer<_ModelCodingKey>
    let key: _ModelCodingKey
    
    var codingPath: [CodingKey] {
        self.container.codingPath
    }
    
    var userInfo: [CodingUserInfoKey : Any] {
        [:]
    }
    
    func container<Key>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key> where Key : CodingKey {
        try self.container.nestedContainer(keyedBy: Key.self, forKey: self.key)
    }
    
    func unkeyedContainer() throws -> UnkeyedDecodingContainer {
        try self.container.nestedUnkeyedContainer(forKey: self.key)
    }
    
    func singleValueContainer() throws -> SingleValueDecodingContainer {
        self
    }
    
    func decode<T>(_ type: T.Type) throws -> T where T : Decodable {
        try self.container.decode(T.self, forKey: self.key)
    }
    
    func decodeNil() -> Bool {
        do {
            return try self.container.decodeNil(forKey: self.key)
        } catch {
            return true
        }
    }
}

private struct ContainerEncoder: Encoder, SingleValueEncodingContainer {
    var container: KeyedEncodingContainer<_ModelCodingKey>
    let key: _ModelCodingKey
    
    var codingPath: [CodingKey] {
        self.container.codingPath
    }
    
    var userInfo: [CodingUserInfoKey : Any] {
        [:]
    }
    
    func container<Key>(keyedBy type: Key.Type) -> KeyedEncodingContainer<Key> where Key : CodingKey {
        var container = self.container
        return container.nestedContainer(keyedBy: Key.self, forKey: self.key)
    }
    
    func unkeyedContainer() -> UnkeyedEncodingContainer {
        var container = self.container
        return container.nestedUnkeyedContainer(forKey: self.key)
    }
    
    func singleValueContainer() -> SingleValueEncodingContainer {
        self
    }
    
    mutating func encode<T>(_ value: T) throws where T : Encodable {
        try self.container.encode(value, forKey: self.key)
    }
    
    mutating func encodeNil() throws {
        try self.container.encodeNil(forKey: self.key)
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
        fatalError("Property not found on model: \(property)")
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
            info["output"] = output.row
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
}

extension AnyModel {
    func output(from output: DatabaseOutput) throws {
        try self.properties.forEach { (_, property) in
            try property.output(from: output)
        }
    }

    func eagerLoad(from eagerLoads: EagerLoads) throws {
        try self.eagerLoadables.forEach { (_, eagerLoadable) in
            try eagerLoadable.eagerLoad(from: eagerLoads)
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
        try joined.output(
            from: output.row.prefixed(by: Joined.alias + "_").output(for: output.database)
        )
        return joined
    }


    public func joined<Joined>(_ model: Joined.Type) throws -> Joined
        where Joined: FluentKit.Model
    {
        guard let output = self.anyID.cachedOutput else {
            fatalError("Can only access joined models using models fetched from database.")
        }
        let joined = Joined()
        try joined.output(
            from: output.row.prefixed(by: Joined.schema + "_").output(for: output.database)
        )
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

extension Database {
    public func query<Model>(_ model: Model.Type) -> QueryBuilder<Model>
        where Model: FluentKit.Model
    {
        return .init(database: self)
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
