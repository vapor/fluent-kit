extension Fields {
    public typealias OptionalGroup<Value> = OptionalGroupProperty<Self, Value>
        where Value: Fields
}

@propertyWrapper @dynamicMemberLookup
public final class OptionalGroupProperty<Model, Value>
    where Model: FluentKit.Fields, Value: FluentKit.Fields
{
    public let key: FieldKey
    public var value: Value?

    public var projectedValue: OptionalGroupProperty<Model, Value> {
        return self
    }

    public var wrappedValue: Value? {
        get {
            return self.value
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


extension OptionalGroupProperty: PropertyProtocol { }

extension OptionalGroupProperty: AnyProperty {
    public var nested: [AnyProperty] {
        self.value!.properties
    }

    public var path: [FieldKey] {
        [self.key]
    }

    public func input(to input: inout DatabaseInput) {
        if let values = self.value?.input.values, !values.isEmpty  {
            input.values[self.key] = .dictionary(values)
        }
    }

    public func output(from output: DatabaseOutput) throws {
        do {
            try self.value?.output(from: output.nested(self.key))
        } catch FluentError.unexceptedNil(_) {
            self.value = nil
        }
    }

    public func encode(to encoder: Encoder) throws {
        if let value = self.value {
            try value.encode(to: encoder)
        } else {
            var container = encoder.singleValueContainer()
            try container.encodeNil()
        }
    }

    public func decode(from decoder: Decoder) throws {
        self.value = try .init(from: decoder)
    }
}
