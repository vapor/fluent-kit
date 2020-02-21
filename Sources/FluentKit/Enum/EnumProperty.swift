extension Fields {
    public typealias Enum<Value> = EnumProperty<Self, Value>
        where Value: Codable,
            Value: RawRepresentable,
            Value.RawValue == String
}

@propertyWrapper
public final class EnumProperty<Model, Value>
    where Model: FluentKit.Fields,
        Value: Codable,
        Value: RawRepresentable,
        Value.RawValue == String
{
    public let field: FieldProperty<Model, String>

    public var projectedValue: EnumProperty<Model, Value> {
        return self
    }

    public var wrappedValue: Value {
        get {
            if let value = self.field.inputValue {
                switch value {
                case .enumCase(let string):
                    return Value(rawValue: string)!
                default:
                    fatalError("Unexpected enum input value type: \(value)")
                }
            } else if let value = self.field.outputValue {
                return Value(rawValue: value)!
            } else {
                fatalError("Cannot access enum field before it is initialized or fetched: \(self.field.key)")
            }
        }
        set {
            self.field.inputValue = .enumCase(newValue.rawValue)
        }
    }

    public init(key: FieldKey) {
        self.field = .init(key: key)
    }
}

extension EnumProperty: FieldProtocol {
    public var path: [FieldKey] {
        self.field.path
    }
}

extension EnumProperty: AnyProperty {
    var keys: [FieldKey] {
        self.field.keys
    }

    func input(to input: inout DatabaseInput) {
        self.field.input(to: &input)
    }

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
