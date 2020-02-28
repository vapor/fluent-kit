extension Fields {
    @available(*, deprecated, renamed: "CompoundField")
    public typealias NestedField = CompoundField

    public typealias CompoundField<Value> = CompoundFieldProperty<Self, Value>
        where Value: Fields
}

@propertyWrapper @dynamicMemberLookup
public final class CompoundFieldProperty<Model, Value>
    where Model: FluentKit.Fields, Value: FluentKit.Fields
{
    public let key: FieldKey
    public var value: Value?

    public var projectedValue: CompoundFieldProperty<Model, Value> {
        return self
    }

    public var wrappedValue: Value {
        get {
            guard let value = self.value else {
                fatalError("Cannot access unitialized Compound field.")
            }
            return value
        }
        set {
            self.value = newValue
        }
    }

    public init(key: FieldKey) {
        self.key = key
        self.value = .init()
    }

    public subscript<Property>(
         dynamicMember keyPath: KeyPath<Value, Property>
    ) -> NestedProperty<Model, Property> {
        .init(prefix: [self.key], property: self.value![keyPath: keyPath])
    }
}


extension CompoundFieldProperty: PropertyProtocol { }

extension CompoundFieldProperty: AnyProperty {
    public var fields: [AnyField] {
        self.wrappedValue.fields.map {
            AnyCompoundField(key: self.key, base: $0)
        }
    }

    public var path: [FieldKey] {
        [self.key]
    }

    public func input(to input: inout DatabaseInput) {
        let values = self.value!.input.values
        if !values.isEmpty {
            input.values[self.key] = .dictionary(values)
        }
    }

    public func output(from output: DatabaseOutput) throws {
        try self.value!.output(from: output.nested(self.key))
    }

    public func encode(to encoder: Encoder) throws {
        try self.value!.encode(to: encoder)
    }

    public func decode(from decoder: Decoder) throws {
        self.value = try .init(from: decoder)
    }
}

private final class AnyCompoundField {
    let key: FieldKey
    let base: AnyField
    init(key: FieldKey, base: AnyField) {
        self.key = key
        self.base = base
    }
}

extension AnyCompoundField: AnyField { }

extension AnyCompoundField: AnyProperty {
    var fields: [AnyField] {
        [self]
    }

    var path: [FieldKey] {
        [self.key] + self.base.path
    }

    var anyValue: Any? {
        self.base.anyValue
    }

    static var anyValueType: Any.Type {
        fatalError()
    }

    func input(to input: inout DatabaseInput) {
        self.base.input(to: &input)
    }

    func output(from output: DatabaseOutput) throws {
        try self.base.output(from: output)
    }

    func encode(to encoder: Encoder) throws {
        try self.base.encode(to: encoder)
    }

    func decode(from decoder: Decoder) throws {
        try self.base.decode(from: decoder)
    }
}
