extension Fields {
    public typealias OptionalField<Value> = OptionalFieldProperty<Self, Value>
        where Value: Codable
}

// MARK: Type

@propertyWrapper
public final class OptionalFieldProperty<Model, Value>
    where Model: FluentKit.Fields, Value: Codable
{
    public let key: FieldKey
    var outputValue: Value?
    var inputValue: DatabaseQuery.Value?

    public var projectedValue: OptionalFieldProperty<Model, Value> {
        self
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
        self.key = key
    }
}

// MARK: Property

extension OptionalFieldProperty: AnyProperty { }

extension OptionalFieldProperty: Property {
    public var value: Value? {
        get {
            if let value = self.inputValue {
                switch value {
                case .bind(let bind):
                    return bind as? Value
                case .enumCase(let string):
                    return string as? Value
                case .default:
                    fatalError("Cannot access default field for '\(Model.self).\(key)' before it is initialized or fetched")
                case .null:
                    return nil
                default:
                    fatalError("Unexpected input value type for '\(Model.self).\(key)': \(value)")
                }
            } else if let value = self.outputValue {
                return value
            } else {
                return nil
            }
        }
        set {
            self.inputValue = newValue.map { .bind($0) } ?? .null
        }
    }
}

// MARK: Queryable

extension OptionalFieldProperty: AnyQueryableProperty {
    public var path: [FieldKey] {
        [self.key]
    }
}

extension OptionalFieldProperty: QueryableProperty { }

// MARK: Database

extension OptionalFieldProperty: AnyDatabaseProperty {
    public var keys: [FieldKey] {
        [self.key]
    }

    public func input(to input: DatabaseInput) {
        if let inputValue = self.inputValue {
            input.set(inputValue, at: self.key)
        }
    }

    public func output(from output: DatabaseOutput) throws {
        if output.contains(self.key) {
            self.inputValue = nil
            do {
                if try output.decodeNil(self.key) {
                    self.outputValue = nil
                } else {
                    self.outputValue = try output.decode(self.key, as: Value.self)
                }
            } catch {
                throw FluentError.invalidField(
                    name: self.key.description,
                    valueType: Value.self,
                    error: error
                )
            }
        }
    }
}

// MARK: Codable

extension OptionalFieldProperty: AnyCodableProperty {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(self.wrappedValue)
    }

    public func decode(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            self.value = nil
        } else {
            self.value = try container.decode(Value.self)
        }
    }
}
