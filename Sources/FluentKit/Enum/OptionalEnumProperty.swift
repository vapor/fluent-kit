extension Fields {
    public typealias OptionalEnum<Value> = OptionalEnumProperty<Self, Value>
        where Value: Codable,
            Value: RawRepresentable,
            Value.RawValue == String
}

@propertyWrapper
public final class OptionalEnumProperty<Model, Value>
    where Model: FluentKit.Fields,
        Value: Codable,
        Value: RawRepresentable,
        Value.RawValue == String
{
    public let field: OptionalFieldProperty<Model, String>

    public var projectedValue: OptionalEnumProperty<Model, Value> {
        return self
    }

    public var wrappedValue: Value? {
        get {
            self.value
        }
        set {
            self.value = newValue
        }
    }

    public init(key: FieldKey) {
        self.field = .init(key: key)
    }
}

extension OptionalEnumProperty: PropertyProtocol {
    public var value: Value? {
        get {
            if let value = self.field.inputValue {
                switch value {
                case .enumCase(let string):
                    return Value(rawValue: string)!
                case .bind(let string as String):
                    guard let value = Value(rawValue: string) else {
                        fatalError("Invalid enum case name '\(string)' for enum \(Value.self)")
                    }

                    return value
                default:
                    fatalError("Unexpected enum input value type: \(value)")
                }
            } else if let value = self.field.outputValue {
                return Value(rawValue: value)!
            } else {
                return nil
            }
        }
        set {
            self.field.inputValue = newValue.flatMap {
                .enumCase($0.rawValue)
            }
        }
    }
}

extension OptionalEnumProperty: FieldProtocol {
    public typealias FilterValue = Value?

    public static func queryValue(_ value: Value?) -> DatabaseQuery.Value {
        if let string = value?.rawValue {
            return .enumCase(string)
        } else {
            return .null
        }
    }
}

extension OptionalEnumProperty: AnyField {
    public var path: [FieldKey] {
        self.field.path
    }
}

extension OptionalEnumProperty: AnyProperty {
    public var nested: [AnyProperty] {
        []
    }

    public func input(to input: inout DatabaseInput) {
        self.field.input(to: &input)
    }

    public func output(from output: DatabaseOutput) throws {
        try self.field.output(from: output)
    }

    public func encode(to encoder: Encoder) throws {
        try self.field.encode(to: encoder)
    }

    public func decode(from decoder: Decoder) throws {
        try self.field.decode(from: decoder)
    }
}

