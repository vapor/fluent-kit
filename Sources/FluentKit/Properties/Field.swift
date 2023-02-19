extension Fields {
    public typealias Field<Value> = FieldProperty<Self, Value>
        where Value: Codable
}

// MARK: Type

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

extension FieldProperty: CustomStringConvertible {
    public var description: String {
        "@\(Model.self).Field<\(Value.self)>(key: \(self.key))"
    }
}

// MARK: Property

extension FieldProperty: AnyProperty { }

extension FieldProperty: Property {
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
            self.inputValue = newValue.map { .bind($0) }
        }
    }
}

// MARK: Queryable

extension FieldProperty: AnyQueryableProperty {
    public var path: [FieldKey] {
        [self.key]
    }
}

extension FieldProperty: QueryableProperty { }

// MARK: Query-addressable

extension FieldProperty: AnyQueryAddressableProperty {
    public var anyQueryableProperty: AnyQueryableProperty { self }
    public var queryablePath: [FieldKey] { self.path }
}

extension FieldProperty: QueryAddressableProperty {
    public var queryableProperty: FieldProperty<Model, Value> { self }
}

// MARK: Database

extension FieldProperty: AnyDatabaseProperty {
    public var keys: [FieldKey] {
        [self.key]
    }

    public func input(to input: DatabaseInput) {
        if input.wantsUnmodifiedKeys {
            input.set(self.inputValue ?? self.outputValue.map { .bind($0) } ?? .default, at: self.key)
        } else if let inputValue = self.inputValue {
            input.set(inputValue, at: self.key)
        }
    }

    public func output(from output: DatabaseOutput) throws {
        if output.contains(self.key) {
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
}

// MARK: Codable

extension FieldProperty: AnyCodableProperty {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(self.wrappedValue)
    }

    public func decode(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if let valueType = Value.self as? AnyOptionalType.Type {
            // Hacks for supporting optionals in @Field.
            // Using @OptionalField is preferred moving forward.
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
