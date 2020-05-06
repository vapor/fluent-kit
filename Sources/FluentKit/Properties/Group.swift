extension Fields {
    public typealias Group<Value> = GroupProperty<Self, Value>
        where Value: Fields
}

enum GroupStructure {
    case flat
    case nested
}

@propertyWrapper @dynamicMemberLookup
public final class GroupProperty<Model, Value>
    where Model: FluentKit.Fields, Value: FluentKit.Fields
{
    public let key: FieldKey
    public var value: Value?
    let structure: GroupStructure

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

    public init(key: FieldKey/*, structure: GroupStructure = .flat*/) {
        self.key = key
        self.value = .init()
        self.structure = .flat
    }

    public subscript<Property>(
         dynamicMember keyPath: KeyPath<Value, Property>
    ) -> GroupedProperty<Model, Property>
        where Property: PropertyProtocol
    {
        .init(
            structure: self.structure,
            prefix: self.key,
            property: self.value![keyPath: keyPath]
        )
    }
}

@dynamicMemberLookup
public final class GroupedProperty<Model, Property>
    where Model: Fields
{
    let structure: GroupStructure
    let prefix: FieldKey
    let property: Property

    init(structure: GroupStructure, prefix: FieldKey, property: Property) {
        self.structure = structure
        self.prefix = prefix
        self.property = property
    }

    public subscript<Value>(
         dynamicMember keyPath: KeyPath<Property, Value>
    ) -> GroupedProperty<Model, Value> {
        .init(
            structure: self.structure,
            prefix: self.prefix,
            property: self.property[keyPath: keyPath]
        )
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
        self.property.key
    }

    public var path: [FieldKey] {
        switch self.structure {
        case .flat:
            return [
                .prefix(.prefix(self.prefix, .string("_")), self.property.path[0])
            ] + self.property.path[1...]
        case .nested:
            return [self.prefix] + self.property.path
        }
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
        switch self.structure {
        case .flat:
            return Value.keys.map {
                .prefix(.prefix(self.key, .string("_")), $0)
            }
        case .nested:
            return [self.key]
        }
    }

    public func input(to input: inout DatabaseInput) {
        let values = self.value!.input.values
        switch self.structure {
        case .flat:
            for value in values {
                input.values[.prefix(.prefix(self.key, .string("_")), value.key)] = value.value
            }
        case .nested:
            input.values[self.key] = .dictionary(values)
        }
    }

    public func output(from output: DatabaseOutput) throws {
        switch self.structure {
        case .flat:
            try self.value!.output(from: output.prefixed(by: self.key))
        case .nested:
            try self.value!.output(from: output.nested(self.key))
        }

    }

    public func encode(to encoder: Encoder) throws {
        try self.value!.encode(to: encoder)
    }

    public func decode(from decoder: Decoder) throws {
        self.value = try .init(from: decoder)
    }
}
