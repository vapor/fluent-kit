extension Fields {
    public typealias CompoundField<Value> = CompoundFieldProperty<Self, Value>
        where Value: Fields
}

@propertyWrapper
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
}

extension CompoundFieldProperty: CompoundFieldPropertyProtocol {
    public var prefix: [FieldKey] {
        [self.key]
    }
}

@dynamicMemberLookup
public protocol CompoundFieldPropertyProtocol: PropertyProtocol
    where Value: Fields
{
    var prefix: [FieldKey] { get }
    subscript<Property>(
         dynamicMember keyPath: KeyPath<Value, Property>
    ) -> PrefixedProperty<Value, Property>
        where
            Property: PropertyProtocol,
            Property.Model == Value
        { get }
}

extension CompoundFieldPropertyProtocol {
    public subscript<Property>(
         dynamicMember keyPath: KeyPath<Value, Property>
    ) -> PrefixedProperty<Value, Property>
        where Property: PropertyProtocol,
            Property.Model == Value
    {
        self.value![keyPath: keyPath].prefixed(by: self.prefix)
    }
}

extension CompoundFieldProperty: PropertyProtocol { }

extension CompoundFieldProperty: AnyProperty {
    public var fields: [AnyField] {
        self.wrappedValue.fields.map {
            $0.prefixed(by: self.prefix)
        }
    }

    public func input(to input: inout DatabaseInput) {
        input.values[self.key] = .dictionary(self.value!.input.values)
    }

    public func output(from output: DatabaseOutput) throws {
        try self.value!.output(from: output.nested(self.key))
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(self.wrappedValue)
    }

    public func decode(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let valueType = Value.self as? AnyOptionalType.Type {
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

private extension AnyField {
    func prefixed(by prefix: [FieldKey]) -> AnyField {
        PrefixedAnyField(prefix: prefix, field: self)
    }
}

private final class PrefixedAnyField: AnyField {
    let prefix: [FieldKey]
    let field: AnyField

    init(prefix: [FieldKey], field: AnyField) {
        self.prefix = prefix
        self.field = field
    }

    var path: [FieldKey] {
        self.prefix + self.field.path
    }

    var fields: [AnyField] {
        [self]
    }

    func input(to input: inout DatabaseInput) {
        self.field.input(to: &input)
    }

    func output(from output: DatabaseOutput) throws {
        try self.field.output(from: output)
    }

    func encode(to encoder: Encoder) throws {
        try self.field.encode(to: encoder)
    }

    func decode(from decoder: Decoder) throws {
        try self.field.decode(from: decoder)
    }
}

private extension PropertyProtocol {
    func prefixed(by prefix: [FieldKey]) -> PrefixedProperty<Model, Self> {
        .init(prefix: prefix, property: self)
    }
}

public final class PrefixedProperty<Model, Property>
    where Model: Fields, Property: PropertyProtocol
{
    public let prefix: [FieldKey]
    public let property: Property
    init(prefix: [FieldKey], property: Property) {
        self.prefix = prefix
        self.property = property
    }
}

extension PrefixedProperty: CompoundFieldPropertyProtocol
    where Property: CompoundFieldPropertyProtocol
{
    public var prefix: [FieldKey] {
        self.prefix + self.property.prefix
    }
}

extension PrefixedProperty: PropertyProtocol {
    public typealias Model = Property.Model
    public typealias Value = Property.Value

    public var value: Value? {
        get {
            self.property.value
        }
        set {
            self.property.value = newValue
        }
    }
}

extension PrefixedProperty: AnyProperty {
    public var fields: [AnyField] {
        self.property.fields
    }

    public func input(to input: inout DatabaseInput) {
        self.property.input(to: &input)
    }

    public func output(from output: DatabaseOutput) throws {
        try self.property.output(from: output)
    }

    public func encode(to encoder: Encoder) throws {
        try self.property.encode(to: encoder)
    }

    public func decode(from decoder: Decoder) throws {
        try self.property.decode(from: decoder)
    }
}

extension PrefixedProperty: FieldProtocol where Property: FieldProtocol { }

extension PrefixedProperty: AnyField where Property: AnyField {
    public var path: [FieldKey] {
        self.prefix + self.property.path
    }
}

