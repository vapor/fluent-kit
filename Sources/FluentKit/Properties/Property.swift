protocol Property {
    var name: String { get }
    var type: Any.Type { get }
    
    var dataType: DatabaseSchema.DataType? { get }
    var constraints: [DatabaseSchema.FieldConstraint] { get }

    func cached(from output: DatabaseOutput) throws -> Any?
    func encode(to encoder: inout ModelEncoder, from storage: Storage) throws
    func decode(from decoder: ModelDecoder, to storage: inout Storage) throws
}

extension Model {
    var properties: [Property] {
        return Mirror(reflecting: self)
            .children
            .compactMap { $0.value as? Property }
    }
}

struct ModelDecoder {
    private var container: KeyedDecodingContainer<_ModelCodingKey>
    
    init(decoder: Decoder) throws {
        self.container = try decoder.container(keyedBy: _ModelCodingKey.self)
    }
    
    public func decode<Value>(_ value: Value.Type, forKey key: String) throws -> Value
        where Value: Decodable
    {
        return try self.container.decode(Value.self, forKey: .string(key))
    }
}

struct ModelEncoder {
    private var container: KeyedEncodingContainer<_ModelCodingKey>
    
    init(encoder: Encoder) {
        self.container = encoder.container(keyedBy: _ModelCodingKey.self)
    }
    
    public mutating func encode<Value>(_ value: Value, forKey key: String) throws
        where Value: Encodable
    {
        try self.container.encode(value, forKey: .string(key))
    }
}

private enum _ModelCodingKey: CodingKey {
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
