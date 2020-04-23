extension Fields {
    public typealias OptionalGroup<Value> = OptionalGroupProperty<Self, Value>
        where Value: Fields
}

@propertyWrapper @dynamicMemberLookup
public final class OptionalGroupProperty<Model, Value>
    where Model: FluentKit.Fields, Value: FluentKit.Fields
{
    @FieldProperty<Model, Bool>
    public var exists: Bool

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

    public init(key: FieldKey, existsKey: FieldKey = .string("exists")) {
        self.key = key
        self._exists = .init(key: key)
        self.value = .init()
    }

    public subscript<Property>(
         dynamicMember keyPath: KeyPath<Value, Property>
    ) -> NestedProperty<Model, Property>
        where Property: PropertyProtocol
    {
        return .init(prefix: [self.key], property: self.value![keyPath: keyPath])
    }
}


extension OptionalGroupProperty: PropertyProtocol { }

extension OptionalGroupProperty: AnyProperty {

    public var nested: [AnyProperty] {
        self.value!.properties + [self.$exists]
    }

    public var path: [FieldKey] {
        [self.key]
    }

    public func input(to input: inout DatabaseInput) {
        if var values = self.value?.input.values, !values.isEmpty {
            values[$exists.key] = .bind(true)
            input.values[self.key] = .dictionary(values)
        } else {
            input.values[self.key] = .dictionary([$exists.key: .bind(false)])
        }
    }

    public func output(from output: DatabaseOutput) throws {
        let existsPath = path + [$exists.key]
        if output.contains(existsPath) {
            if try output.decode(existsPath, as: Bool.self) == true {
                let value = Value()
                try value.output(from: output.nested(self.key))
                self.value = value
            } else {
                self.value = nil
            }
        } else {
            fatalError("Missing value for path: \(existsPath)")
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
