extension Model {
    public typealias CompoundField<Value> = CompoundFieldProperty<Self, Value>
        where Value: Fields
}

@propertyWrapper @dynamicMemberLookup
public final class CompoundFieldProperty<Model, Value>
    where Model: FluentKit.Fields, Value: FluentKit.Fields
{
    public let prefix: String

    public var value: Value?

    public var projectedValue: CompoundFieldProperty<Model, Value> {
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

    public init(prefix: String) {
        self.prefix = prefix
    }

    public convenience init(key: String, separator: String = "_") {
        self.init(prefix: key + separator)
    }

    public subscript<Field>(
         dynamicMember keyPath: KeyPath<Value, Field>
    ) -> NestedField<Value, Field>
        where Field: FieldRepresentable,
            Field.Model == Value
    {
        .init(prefix: self.prefix, field: Value()[keyPath: keyPath])
    }
}

public struct NestedField<Model, Field>
    where Model: FluentKit.Fields, Field: FieldRepresentable
{
    public let prefix: String
    public let field: Field
}

extension NestedField: FieldRepresentable {
    public var wrappedValue: Field.Value {
        self.field.wrappedValue
    }

    public var key: FieldKey {
        .prefixed(self.prefix, self.field.key)
    }
}

extension CompoundFieldProperty: AnyProperty {
    var keys: [FieldKey] {
        self.wrappedValue.keys.map {
            .prefixed(self.prefix, $0)
        }
    }

    func input(to input: inout DatabaseInput) {
        if let value = self.value {
            value.input.fields.forEach { (name, value) in
                input.fields[.prefixed(self.prefix, name)] = value
            }
        }
    }

    func output(from output: DatabaseOutput) throws {
        let value = Value()
        try value.output(from: output.prefixed(by: self.prefix))
        self.value = value
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
