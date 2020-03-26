public protocol FieldValueConverter {
    associatedtype Value: Codable

    func value(from databaseValue: DatabaseQuery.Value) -> Value?
    func databaseValue(from value: Value) -> DatabaseQuery.Value

    func decode(from output: DatabaseOutput) throws -> Value

    func encode(_ value: Value, to container: inout SingleValueEncodingContainer) throws
    func decode(from container: SingleValueDecodingContainer) throws -> Value
}

extension FieldValueConverter {
    public func databaseValue(from value: Value) -> DatabaseQuery.Value { .bind(value) }

    public func encode(_ value: Value, to container: inout SingleValueEncodingContainer) throws { try container.encode(value) }
    public func decode(from container: SingleValueDecodingContainer) throws -> Value { try container.decode(Value.self) }
}


public struct AnyFieldValueConverter<Value>: FieldValueConverter where Value: Codable {
    private let valueToDatabase: (Value) -> DatabaseQuery.Value
    private let databaseToValue: (DatabaseQuery.Value) -> Value?

    private let deocdeOutput: (DatabaseOutput) throws -> Value

    private let encodeValue: (Value, inout SingleValueEncodingContainer) throws -> ()
    private let decodeContainer: (SingleValueDecodingContainer) throws -> Value

    public init<Converter>(_ converter: Converter) where Converter: FieldValueConverter, Converter.Value == Value {
        self.valueToDatabase = converter.databaseValue(from:)
        self.databaseToValue = converter.value(from:)

        self.deocdeOutput = converter.decode(from:)

        self.encodeValue = converter.encode(_:to:)
        self.decodeContainer = converter.decode(from:)
    }

    public func value(from databaseValue: DatabaseQuery.Value) -> Value? {
        return self.databaseToValue(databaseValue)
    }

    public func databaseValue(from value: Value) -> DatabaseQuery.Value {
        return self.valueToDatabase(value)
    }

    public func decode(from output: DatabaseOutput) throws -> Value {
        try self.deocdeOutput(output)
    }

    public func encode(_ value: Value, to container: inout SingleValueEncodingContainer) throws {
        try self.encodeValue(value, &container)
    }

    public func decode(from container: SingleValueDecodingContainer) throws -> Value {
        return try self.decodeContainer(container)
    }
}

public struct DefaultFieldValueConverter<Value>: FieldValueConverter where Value: Codable {
    public let modelType: Fields.Type
    public let key: FieldKey

    public init(_ model: Fields.Type, key: FieldKey) {
        self.modelType = model
        self.key = key
    }

    public func value(from databaseValue: DatabaseQuery.Value) -> Value? {
        switch databaseValue {
        case .bind(let bind):
            return bind as? Value
        case .enumCase(let string):
            return string as? Value
        case .default:
            fatalError("Cannot access default field for '\(self.modelType).\(self.key)' before it is initialized or fetched")
        default:
            fatalError("Unexpected input value type for '\(self.modelType).\(self.key)': \(databaseValue)")
        }
    }

    public func decode(from output: DatabaseOutput) throws -> Value {
        return try output.decode(self.key, as: Value.self)
    }
}
