extension Fields {
    @available(*, deprecated, renamed: "Group")
    public typealias NestedField = Group
    @available(*, deprecated, renamed: "Group")
    public typealias CompoundField = Group

    public typealias Group<Value> = GroupProperty<Self, Value>
        where Value: Fields
}

@propertyWrapper @dynamicMemberLookup
public final class GroupProperty<Model, Value>
    where Model: FluentKit.Fields, Value: FluentKit.Fields
{
    public let key: FieldKey
    public var value: Value?

    public var projectedValue: GroupProperty<Model, Value> {
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
    ) -> NestedProperty<Model, Property>
        where Property: PropertyProtocol
    {
        .init(prefix: [self.key], property: self.value![keyPath: keyPath])
    }
}


extension GroupProperty: PropertyProtocol { }

extension GroupProperty: AnyProperty {
    public var nested: [AnyProperty] {
        self.value!.properties
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
