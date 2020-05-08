extension Fields {
    public typealias OptionalEnum<Value> = OptionalEnumProperty<Self, Value>
        where Value: Codable,
            Value: RawRepresentable,
            Value.RawValue == String
}

// MARK: Type

@propertyWrapper
public final class OptionalEnumProperty<Model, WrappedValue>
    where Model: FluentKit.Fields,
        WrappedValue: Codable,
        WrappedValue: RawRepresentable,
        WrappedValue.RawValue == String
{
    public let field: OptionalFieldProperty<Model, String>

    public var projectedValue: OptionalEnumProperty<Model, WrappedValue> {
        return self
    }

    public var wrappedValue: WrappedValue? {
        get {
            guard let value = self.value else {
                fatalError("Cannot access @OptionalEnum before it is initialized or fetched: \(self.field.key)")
            }
            return value
        }
        set {
            self.value = newValue
        }
    }

    public init(key: FieldKey) {
        self.field = .init(key: key)
    }
}

// MARK: Property

extension OptionalEnumProperty: AnyProperty { }

extension OptionalEnumProperty: Property {
    public var value: WrappedValue?? {
        get {
            if let value = self.field.inputValue {
                switch value {
                case .bind(let string as String),
                     .enumCase(let string):
                    guard let value = WrappedValue(rawValue: string) else {
                        fatalError("Invalid enum case name '\(string)' for enum \(Value.self)")
                    }
                    return .some(value)
                default:
                    fatalError("Unexpected enum input value type: \(value)")
                }
            } else if let value = self.field.outputValue {
                return .some(value.flatMap { WrappedValue(rawValue: $0) })
            } else {
                return .none
            }
        }
        set {
            if let value = newValue {
                self.field.inputValue = value.flatMap { .enumCase($0.rawValue) } ?? .null
            } else {
                self.field.inputValue = nil
            }
        }
    }
}

// MARK: Queryable

extension OptionalEnumProperty: AnyQueryableProperty {
    public var path: [FieldKey] {
        self.field.path
    }
}

extension OptionalEnumProperty: QueryableProperty {
    public static func queryValue(_ value: Value) -> DatabaseQuery.Value {
        value.flatMap { .enumCase($0.rawValue) } ?? .null
    }
}

// MARK: Database

extension OptionalEnumProperty: AnyDatabaseProperty {
    public var keys: [FieldKey] {
        self.field.keys
    }

    public func input(to input: DatabaseInput) {
        self.field.input(to: input)
    }

    public func output(from output: DatabaseOutput) throws {
        try self.field.output(from: output)
    }
}

// MARK: Codable

extension OptionalEnumProperty: AnyCodableProperty {
    public func encode(to encoder: Encoder) throws {
        try self.field.encode(to: encoder)
    }

    public func decode(from decoder: Decoder) throws {
        try self.field.decode(from: decoder)
    }
}

