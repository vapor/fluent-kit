extension Fields {
    public init(from decoder: Decoder) throws {
        self.init()
        let container = try decoder.container(keyedBy: ModelCodingKey.self)
        try self.labeledProperties.compactMapValues {
            $0 as? AnyCodableProperty
        }.forEach { label, property in
            do {
                let decoder = ContainerDecoder(container: container, key: .string(label))
                try property.decode(from: decoder)
            } catch {
                throw DecodingError.typeMismatch(
                    type(of: property).anyValueType,
                    .init(
                        codingPath: [ModelCodingKey.string(label)],
                        debugDescription: "Could not decode property",
                        underlyingError: error
                    )
                )
            }
        }
    }

    public func encode(to encoder: Encoder) throws {
        let container = encoder.container(keyedBy: ModelCodingKey.self)
        try self.labeledProperties.compactMapValues {
            $0 as? AnyCodableProperty
        }.forEach { label, property in
            do {
                let encoder = ContainerEncoder(container: container, key: .string(label))
                try property.encode(to: encoder)
            } catch {
                throw EncodingError.invalidValue(
                    property.anyValue ?? "null",
                    .init(
                        codingPath: [ModelCodingKey.string(label)],
                        debugDescription: "Could not encode property",
                        underlyingError: error
                    )
                )
            }
        }
    }
}

enum ModelCodingKey: CodingKey {
    case string(String)
    case int(Int)

    var stringValue: String {
        switch self {
        case .int(let int): return int.description
        case .string(let string): return string
        }
    }

    var intValue: Int? {
        switch self {
        case .int(let int): return int
        case .string(let string): return Int(string)
        }
    }

    init?(stringValue: String) {
        self = .string(stringValue)
    }

    init?(intValue: Int) {
        self = .int(intValue)
    }
}


private struct ContainerDecoder: Decoder, SingleValueDecodingContainer {
    let container: KeyedDecodingContainer<ModelCodingKey>
    let key: ModelCodingKey

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
        if self.container.contains(self.key) {
            return try! self.container.decodeNil(forKey: self.key)
        } else {
            return true
        }
    }
}

private struct ContainerEncoder: Encoder, SingleValueEncodingContainer {
    var container: KeyedEncodingContainer<ModelCodingKey>
    let key: ModelCodingKey

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
