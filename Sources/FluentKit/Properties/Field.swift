extension Fields {
    public typealias Field<Value> = FieldProperty<Self, Value>
        where Value: Codable
}

@propertyWrapper
public final class FieldProperty<Model, Value>
    where Model: FluentKit.Fields, Value: Codable
{
    public let key: FieldKey
    var outputValue: Value?
    var inputValue: DatabaseQuery.Value?
    
    public var projectedValue: FieldProperty<Model, Value> {
        self
    }

    public var wrappedValue: Value {
        get {
            guard let value = self.value else {
                fatalError("Cannot access field before it is initialized or fetched: \(self.key)")
            }
            return value
        }
        set {
            self.value = newValue
        }
    }

    public init(key: FieldKey) {
        self.key = key
    }
}

extension FieldProperty: PropertyProtocol {
    public var value: Value? {
        get {
            if let value = self.inputValue {
                switch value {
                case .bind(let bind):
                    return bind as? Value
                case .default:
                    fatalError("Cannot access default field before it is initialized or fetched")
                default:
                    fatalError("Unexpected input value type: \(value)")
                }
            } else if let value = self.outputValue {
                return value
            } else {
                return nil
            }
        }
        set {
            self.inputValue = .bind(newValue)
        }
    }
}

extension FieldProperty: FieldProtocol { }

extension FieldProperty: AnyField {
    public var path: [FieldKey] {
        [self.key]
    }
}

extension FieldProperty: AnyProperty {
    public var fields: [AnyField] {
        [self]
    }

    public func input(to input: inout DatabaseInput) {
        input.values[self.key] = self.inputValue
    }

    public func output(from output: DatabaseOutput) throws {
        if output.contains([self.key]) {
            self.inputValue = nil
            do {
                self.outputValue = try output.decode(self.key, as: Value.self)
            } catch {
                throw FluentError.invalidField(
                    name: self.key.description,
                    valueType: Value.self,
                    error: error
                )
            }
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(self.wrappedValue)
    }

    public func decode(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let valueType = Value.self as? AnyOptionalType.Type {
            if container.decodeNil() {
                self.wrappedValue = (valueType.nil as! Value)
            } else {
                self.wrappedValue = try container.decode(Value.self)
            }
        } else {
            self.wrappedValue = try container.decode(Value.self)
        }
    }
}
