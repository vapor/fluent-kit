protocol AnyProperty: class {
    func output(from output: DatabaseOutput) throws
    func encode(to encoder: Encoder) throws
    func decode(from decoder: Decoder) throws
}

extension AnyProperty where Self: FieldRepresentable {
    func output(from output: DatabaseOutput) throws {
        try self.field.output(from: output)
    }

    func encode(to encoder: Encoder) throws {
        try self.field.encode(to: encoder)
    }

    func decode(from decoder: Decoder) throws {
        try self.field.decode(from: decoder)
    }
}

protocol AnyField: AnyProperty {
    var key: String { get }
    var inputValue: DatabaseQuery.Value? { get set }
}

extension AnyField where Self: FieldRepresentable {
    var key: String {
        return self.field.key
    }

    var inputValue: DatabaseQuery.Value? {
        get { self.field.inputValue }
        set { self.field.inputValue = newValue }
    }
}

public protocol EagerLoadable {
    func eagerLoad<Model>(to builder: QueryBuilder<Model>)
        where Model: FluentKit.Model
}

protocol AnyEagerLoadable: AnyProperty {
    var eagerLoadKey: String { get }
    var eagerLoadValueDescription: CustomStringConvertible? { get }
    func eagerLoad(from eagerLoads: EagerLoads) throws
}

protocol AnyID: AnyField {
    func generate()
    var exists: Bool { get set }
    var cachedOutput: DatabaseOutput? { get set }
}

public protocol FieldRepresentable {
    associatedtype Value: Codable
    var field: Field<Value> { get }
}

extension AnyField { }

extension AnyModel {
    var eagerLoadables: [(String, AnyEagerLoadable)] {
        self.properties.compactMap {
            guard let value = $1 as? AnyEagerLoadable else {
                return nil
            }
            return ($0, value)
        }
    }

    var fields: [(String, AnyField)] {
        self.properties.compactMap {
            guard let value = $1 as? AnyField else {
                return nil
            }
            return ($0, value)
        }
    }
    
    var properties: [(String, AnyProperty)] {
        return Mirror(reflecting: self)
            .children
            .compactMap { child in
                guard let label = child.label else {
                    return nil
                }
                guard let property = child.value as? AnyProperty else {
                    return nil
                }
                // remove underscore
                return (String(label.dropFirst()), property)
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

enum _ModelCodingKey: CodingKey {
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
