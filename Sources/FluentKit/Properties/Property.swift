protocol AnyProperty {
    var name: String { get }
    func encode(to encoder: inout ModelEncoder, from row: AnyRow) throws
    func decode(from decoder: ModelDecoder, to row: AnyRow) throws
}

protocol AnyField: AnyProperty {
    var type: Any.Type { get }
    func cached(from output: DatabaseOutput) throws -> Any?
    var dataType: DatabaseSchema.DataType? { get }
    var constraints: [DatabaseSchema.FieldConstraint] { get }
}

extension Model {
    var fields: [AnyField] {
        return Mirror(reflecting: self)
            .children
            .compactMap { $0.value as? AnyField }
    }
    
    var properties: [AnyProperty] {
        return Mirror(reflecting: self)
            .children
            .compactMap { $0.value as? AnyProperty }
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
