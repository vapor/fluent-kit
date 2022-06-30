extension Fields {
    public typealias Boolean<Format> = BooleanProperty<Self, Format>
        where Format: BooleanPropertyFormat
}

@propertyWrapper
public final class BooleanProperty<Model, Format>
    where Model: FluentKit.Fields, Format: BooleanPropertyFormat
{
    @FieldProperty<Model, Format.Value>
    public var field: Format.Value
    public let format: Format

    public var projectedValue: BooleanProperty<Model, Format> { self }

    public var wrappedValue: Bool {
        get {
            guard let value = self.value else {
                fatalError("Cannot access bool field before it is initialized or fetched: \(self.$field.key)")
            }
            return value
        }
        set { self.value = newValue }
    }

    public init(key: FieldKey, format: Format) {
        self._field = .init(key: key)
        self.format = format
    }
}

extension BooleanProperty where Format == DefaultBooleanPropertyFormat {
    public convenience init(key: FieldKey) {
        self.init(key: key, format: .default)
    }
}

extension BooleanProperty: AnyProperty {}

extension BooleanProperty: Property {
    public var value: Bool? {
        get { self.$field.value.map { self.format.parse($0)! } }
        set { self.$field.value = newValue.map { self.format.serialize($0) } }
    }
}

extension BooleanProperty: AnyQueryableProperty {
    public var path: [FieldKey] { self.$field.path }
}

extension BooleanProperty: QueryableProperty {
    public static func queryValue(_ value: Bool) -> DatabaseQuery.Value {
        .bind(Format.init().serialize(value))
    }
}

extension BooleanProperty: AnyQueryAddressableProperty {
    public var anyQueryableProperty: AnyQueryableProperty { self }
    public var queryablePath: [FieldKey] { self.path }
}

extension BooleanProperty: QueryAddressableProperty {
    public var queryableProperty: BooleanProperty<Model, Format> { self }
}

extension BooleanProperty: AnyDatabaseProperty {
    public var keys: [FieldKey] { self.$field.keys }
    public func input(to input: DatabaseInput) { self.$field.input(to: input) }
    public func output(from output: DatabaseOutput) throws { try self.$field.output(from: output) }
}

extension BooleanProperty: AnyCodableProperty {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(self.wrappedValue)
    }

    public func decode(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        self.value = try container.decode(Value.self)
    }
}
