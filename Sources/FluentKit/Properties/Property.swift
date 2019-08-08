protocol AnyProperty: class {
    func output(from output: DatabaseOutput, label: String) throws
    func encode(to encoder: inout ModelEncoder, label: String) throws
    func decode(from decoder: ModelDecoder, label: String) throws
}

protocol AnyEagerLoadable: AnyProperty {
    func eagerLoad(from eagerLoads: EagerLoads, label: String) throws
    func eagerLoad(to eagerLoads: EagerLoads, method: EagerLoadMethod, label: String)
}

protocol AnyField: AnyProperty {
    func key(label: String) -> String
    var inputValue: DatabaseQuery.Value? { get set }
    var cachedOutput: DatabaseOutput? { get }
    var exists: Bool { get set }
}

extension AnyField { }

extension AnyModel {
    var eagerLoadables: [(String, AnyEagerLoadable)] {
        return self.properties.compactMap { (label, property) in
            guard let eagerLoadable = property as? AnyEagerLoadable else {
                return nil
            }
            return (label, eagerLoadable)
        }
    }

    var fields: [(String, AnyField)] {
        return self.properties.compactMap { (label, property) in
            guard let field = property as? AnyField else {
                return nil
            }
            return (label, field)
        }
    }
    
    var properties: [(String, AnyProperty)] {
        return Mirror(reflecting: self)
            .children
            .compactMap { child in
                guard let label = child.label else {
                    return nil
                }
                guard let value = child.value as? AnyProperty else {
                    return nil
                }
                // remove underscore
                return (String(label.dropFirst()), value)
            }
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

    public func has(key: String) -> Bool {
        return self.container.contains(.string(key))
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
