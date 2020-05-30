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
            self.field.value = newValue?.map {
                $0.rawValue
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
        if let value = self.value {
            input.set(value.map { .enumCase($0.rawValue) } ?? .null, at: self.field.key)
        }
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

