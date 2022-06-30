extension Fields {
    public typealias OptionalBoolean<Format> = OptionalBooleanProperty<Self, Format>
        where Format: BooleanPropertyFormat
}

@propertyWrapper
public final class OptionalBooleanProperty<Model, Format>
    where Model: FluentKit.Fields, Format: BooleanPropertyFormat
{
    @OptionalFieldProperty<Model, Format.Value>
    public var field: Format.Value?
    public let format: Format

    public var projectedValue: OptionalBooleanProperty<Model, Format> { self }

    public var wrappedValue: Bool? {
        get {
            switch self.value {
            case .none, .some(.none): return nil
            case .some(.some(let value)): return value
            }
        }
        set { self.value = .some(newValue) }
    }

    public init(key: FieldKey, format: Format) {
        self._field = .init(key: key)
        self.format = format
    }
}

extension OptionalBooleanProperty where Format == DefaultBooleanPropertyFormat {
    public convenience init(key: FieldKey) {
        self.init(key: key, format: .default)
    }
}

extension OptionalBooleanProperty: AnyProperty {}

extension OptionalBooleanProperty: Property {
    public var value: Bool?? {
        get {
            switch self.$field.value {
            case .some(.some(let value)): return .some(self.format.parse(value))
            case .some(.none): return .some(.none)
            case .none: return .none
            }
        }
        set {
            switch newValue {
            case .some(.some(let newValue)): self.$field.value = .some(.some(self.format.serialize(newValue)))
            case .some(.none): self.$field.value = .some(.none)
            case .none: self.$field.value = .none
            }
        }
    }
}

extension OptionalBooleanProperty: AnyQueryableProperty {
    public var path: [FieldKey] { self.$field.path }
}

extension OptionalBooleanProperty: QueryableProperty {
    public static func queryValue(_ value: Bool?) -> DatabaseQuery.Value {
        value.map { .bind(Format.init().serialize($0)) } ?? .null
    }
}

extension OptionalBooleanProperty: AnyQueryAddressableProperty {
    public var anyQueryableProperty: AnyQueryableProperty { self }
    public var queryablePath: [FieldKey] { self.path }
}

extension OptionalBooleanProperty: QueryAddressableProperty {
    public var queryableProperty: OptionalBooleanProperty<Model, Format> { self }
}

extension OptionalBooleanProperty: AnyDatabaseProperty {
    public var keys: [FieldKey] { self.$field.keys }
    public func input(to input: DatabaseInput) { self.$field.input(to: input) }
    public func output(from output: DatabaseOutput) throws { try self.$field.output(from: output) }
}

extension OptionalBooleanProperty: AnyCodableProperty {
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
