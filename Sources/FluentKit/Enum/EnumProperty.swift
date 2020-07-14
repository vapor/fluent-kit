extension Fields {
    public typealias Enum<Value> = EnumProperty<Self, Value>
        where Value: Codable,
            Value: RawRepresentable,
            Value.RawValue == String
}

// MARK: Type

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
            guard let value = self.value else {
                fatalError("Cannot access enum field before it is initialized or fetched: \(self.field.key)")
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

extension EnumProperty: AnyProperty { }

extension EnumProperty: Property {
    public var value: Value? {
        get {
            self.field.value.map {
                Value(rawValue: $0)!
            }
        }
        set {
            self.field.value = newValue?.rawValue
        }
    }
}

// MARK: Queryable

extension EnumProperty: AnyQueryableProperty {
    public var path: [FieldKey] {
        self.field.path
    }
}

extension EnumProperty: QueryableProperty {
    public static func queryValue(_ value: Value) -> DatabaseQuery.Value {
        .enumCase(value.rawValue)
    }
}

// MARK: Database

extension EnumProperty: AnyDatabaseProperty {
    public var keys: [FieldKey] {
        self.field.keys
    }

    public func input(to input: DatabaseInput) {
        if let value = self.value {
            input.set(.enumCase(value.rawValue), at: self.field.key)
        }
    }

    public func output(from output: DatabaseOutput) throws {
        try self.field.output(from: output)
    }
}

// MARK: Codable

extension EnumProperty: AnyCodableProperty {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(self.wrappedValue)
    }

    public func decode(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        self.value = try container.decode(Value.self)
    }
}
