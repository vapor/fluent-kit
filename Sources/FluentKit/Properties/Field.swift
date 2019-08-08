@propertyWrapper
public final class Field<Value>: AnyField, Filterable
    where Value: Codable
{
    public let key: String
    var outputValue: Value?
    var inputValue: DatabaseQuery.Value?

    public var projectedValue: Field<Value> {
        return self
    }
    
    public var wrappedValue: Value {
        get {
            if let value = self.inputValue {
                guard case .bind(let bind) = value else {
                    fatalError("Unexpected input value type")
                }
                return bind as! Value
            } else if let value = self.outputValue {
                return value
            } else {
                fatalError("Cannot access field before it is initialized or fetched")
            }
        }
        set {
            self.inputValue = .bind(newValue)
        }
    }

    public init(_ key: String) {
        self.key = key
    }

    // MARK: Property

    func output(from output: DatabaseOutput) throws {
        if output.contains(field: self.key) {
            self.inputValue = nil
            do {
                self.outputValue = try output.decode(field: self.key, as: Value.self)
            } catch {
                throw FluentError.invalidField(name: self.key, valueType: Value.self)
            }
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(self.wrappedValue)
    }

    func decode(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let valueType = Value.self as? _Optional.Type {
            if container.decodeNil() {
                self.wrappedValue = (valueType._none as! Value)
            } else {
                self.wrappedValue = try container.decode(Value.self)
            }
        } else {
            self.wrappedValue = try container.decode(Value.self)
        }
    }
}


private protocol _Optional {
    static var _none: Any { get }
}
extension Optional: _Optional {
    static var _none: Any {
        return Self.none as Any
    }
}
