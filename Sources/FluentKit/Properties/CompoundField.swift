extension Fields {
    public typealias Group<Value> = GroupProperty<Self, Value>
        where Value: Fields
}

public enum GroupMode {
    case compound
    case nested
}

@propertyWrapper @dynamicMemberLookup
public final class GroupProperty<Model, Value>
    where Model: FluentKit.Fields, Value: FluentKit.Fields
{
    public let key: FieldKey
    public var value: Value?
    public let mode: GroupMode

    public var projectedValue: GroupProperty<Model, Value> {
        return self
    }

    public var wrappedValue: Value {
        get {
            guard let value = self.value else {
                fatalError("Cannot access unitialized Group field.")
            }
            return value
        }
        set {
            self.value = newValue
        }
    }

    public init(key: FieldKey, mode: GroupMode = .compound) {
        self.key = key
        self.value = .init()
        self.mode = mode
    }

    public subscript<Property>(
         dynamicMember keyPath: KeyPath<Value, Property>
    ) -> GroupedProperty<Model, Property>
        where Property: PropertyProtocol
    {
        .init(prefix: self.key, property: self.value![keyPath: keyPath])
    }
}

@dynamicMemberLookup
public final class GroupedProperty<Model, Property>
    where Model: Fields
{
    let prefix: FieldKey
    let property: Property

    init(prefix: FieldKey, property: Property) {
        self.prefix = prefix
        self.property = property
    }

    public subscript<Value>(
         dynamicMember keyPath: KeyPath<Property, Value>
    ) -> GroupedProperty<Model, Value> {
        .init(prefix: self.prefix, property: self.property[keyPath: keyPath])
    }
}

extension GroupedProperty: AnyValue where Property: AnyValue {
    public static var anyValueType: Any.Type {
        Property.anyValueType
    }

    public var anyValue: Any? {
        self.property.anyValue
    }
}

extension GroupedProperty: ValueProtocol where Property: ValueProtocol {
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

extension GroupedProperty: AnyField where Property: AnyField {
    public var key: FieldKey {
        .prefix(.prefix(self.prefix, .string("_")), self.property.key)
    }

    public var path: [FieldKey] {
        [self.key]
    }
}

extension GroupedProperty: FieldProtocol where Property: FieldProtocol {
    public static func queryValue(_ value: Value) -> DatabaseQuery.Value {
        Property.queryValue(value)
    }
}

extension GroupProperty: PropertyProtocol { }

extension GroupProperty: AnyProperty {
    public var keys: [FieldKey] {
        Value.keys.map {
            .prefix(.prefix(self.key, .string("_")), $0)
        }
    }

    public func input(to input: inout DatabaseInput) {
        let values = self.value!.input.values
        for value in values {
            input.values[.string("\(self.key)_\(value.key)")] = value.value
        }
    }

    public func output(from output: DatabaseOutput) throws {
        try self.value!.output(from: PrefixedOutput(prefix: self.key, base: output))
    }

    public func encode(to encoder: Encoder) throws {
        try self.value!.encode(to: encoder)
    }

    public func decode(from decoder: Decoder) throws {
        self.value = try .init(from: decoder)
    }
}

private struct PrefixedOutput: DatabaseOutput {
    let prefix: FieldKey
    let base: DatabaseOutput

    func schema(_ schema: String) -> DatabaseOutput {
        PrefixedOutput(prefix: self.prefix, base: self.base.schema(schema))
    }

    func nested(_ key: FieldKey) throws -> DatabaseOutput {
        try self.base.nested(self.key(key))
    }

    func contains(_ key: FieldKey) -> Bool {
        return self.base.contains(self.key(key))
    }

    func decodeNil(_ key: FieldKey) throws -> Bool {
        try self.base.decodeNil(self.key(key))
    }

    func decode<T>(_ key: FieldKey, as type: T.Type) throws -> T
        where T: Decodable
    {
        try self.base.decode(self.key(key))
    }

    func key(_ key: FieldKey) -> FieldKey {
        .prefix(.prefix(self.prefix, .string("_")), key)
    }

    var description: String {
        self.base.description
    }
}
