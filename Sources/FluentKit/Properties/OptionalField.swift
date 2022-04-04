extension Fields {
    public typealias OptionalField<Value> = OptionalFieldProperty<Self, Value>
        where Value: Codable
}

// MARK: Type

@propertyWrapper
public final class OptionalFieldProperty<Model, WrappedValue>
    where Model: FluentKit.Fields, WrappedValue: Codable
{
    public let key: FieldKey
    var outputValue: WrappedValue??
    var inputValue: DatabaseQuery.Value?

    public var projectedValue: OptionalFieldProperty<Model, WrappedValue> {
        self
    }

    public var wrappedValue: WrappedValue? {
        get {
            self.value ?? nil
        }
        set {
            self.value = .some(newValue)
        }
    }

    public init(key: FieldKey) {
        self.key = key
    }
}

// MARK: Property

extension OptionalFieldProperty: AnyProperty { }

extension OptionalFieldProperty: Property {
    public var value: WrappedValue?? {
        get {
            if let value = self.inputValue {
                switch value {
                case .bind(let bind):
                    return .some(bind as? WrappedValue)
                case .enumCase(let string):
                    return .some(string as? WrappedValue)
                case .default:
                    fatalError("Cannot access default field for '\(Model.self).\(key)' before it is initialized or fetched")
                case .null:
                    return .some(.none)
                default:
                    fatalError("Unexpected input value type for '\(Model.self).\(key)': \(value)")
                }
            } else if let value = self.outputValue {
                return .some(value)
            } else {
                return .none
            }
        }
        set {
            if let value = newValue {
                self.inputValue = value
                    .flatMap { .bind($0) }
                    ?? .null
            } else {
                self.inputValue = nil
            }
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
                    self.outputValue = .some(nil)
                } else {
                    self.outputValue = try .some(output.decode(self.key, as: Value.self))
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
