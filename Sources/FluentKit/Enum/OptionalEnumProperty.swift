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
            self.value ?? nil
        }
        set {
            self.value = .some(newValue)
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
            self.field.value.map {
                $0.map {
                    WrappedValue(rawValue: $0)!
                }
            }
        }
        set {
            switch newValue {
            case .some(.some(let newValue)):
                self.field.value = .some(.some(newValue.rawValue))
            case .some(.none):
                self.field.value = .some(.none)
            case .none:
                self.field.value = .none
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

// MARK: Query-addressable

extension OptionalEnumProperty: AnyQueryAddressableProperty {
    public var anyQueryableProperty: AnyQueryableProperty { self }
    public var queryablePath: [FieldKey] { self.path }
}

extension OptionalEnumProperty: QueryAddressableProperty {
    public var queryableProperty: OptionalEnumProperty<Model, WrappedValue> { self }
}

// MARK: Database

extension OptionalEnumProperty: AnyDatabaseProperty {
    public var keys: [FieldKey] {
        self.field.keys
    }

    public func input(to input: DatabaseInput) {
        let value: DatabaseQuery.Value
        if !input.wantsUnmodifiedKeys {
            guard let ivalue = self.field.inputValue else { return }
            value = ivalue
        } else {
            value = self.field.inputValue ?? .default
        }


        switch value {
        case .bind(let bind as String):
            input.set(.enumCase(bind), at: self.field.key)
        case .enumCase(let string):
            input.set(.enumCase(string), at: self.field.key)
        case .null:
            input.set(.null, at: self.field.key)
        case .default:
            input.set(.default, at: self.field.key)
        default:
            fatalError("Unexpected input value type for '\(Model.self)'.'\(self.field.key)': \(value)")
        }
    }

    public func output(from output: DatabaseOutput) throws {
        try self.field.output(from: output)
    }
}

// MARK: Codable

extension OptionalEnumProperty: AnyCodableProperty {
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
