extension Fields {
    public typealias NestedField<Value> = NestedFieldProperty<Self, Value>
        where Value: Fields
}

@propertyWrapper @dynamicMemberLookup
public final class NestedFieldProperty<Model, Value>
    where Model: FluentKit.Fields, Value: FluentKit.Fields
{
    public let key: FieldKey
    public var value: Value?

    public var projectedValue: NestedFieldProperty<Model, Value> {
        return self
    }

    public var wrappedValue: Value {
        get {
            if let existing = self.value {
                return existing
            } else {
                let new = Value()
                self.value = new
                return new
            }
        }
        set {
            self.value = newValue
        }
    }

    public init(key: FieldKey) {
        self.key = key
    }

    public subscript<Field>(
         dynamicMember keyPath: KeyPath<Value, Field>
    ) -> _NestedField<Value, Field>
        where Field: FieldProtocol,
            Field.Model == Value
    {
        .init(root: self.key, field: Value()[keyPath: keyPath])
    }
}

extension NestedFieldProperty: AnyProperty {
    var keys: [FieldKey] {
        [self.key]
    }

    func input(to input: inout DatabaseInput) {
        if let value = self.value {
            input.values[self.key] = .bind(value)
        }
    }

    func output(from output: DatabaseOutput) throws {
        self.value = try output.decode(self.key)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(self.wrappedValue)
    }

    func decode(from decoder: Decoder) throws {
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

public struct _NestedField<Model, Field>
    where Model: FluentKit.Fields, Field: FieldProtocol
{
    public let root: FieldKey
    public let field: Field
}

extension _NestedField: FieldProtocol {
    public var wrappedValue: Field.Value {
        self.field.wrappedValue
    }

    public var path: [FieldKey] {
        [self.root] + self.field.path
    }
}
