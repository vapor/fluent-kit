extension Schema {
    public typealias NestedField<Value> = NestedFieldProperty<Self, Value>
        where Value: Fields
}

@propertyWrapper @dynamicMemberLookup
public final class NestedFieldProperty<Model, Value>
    where Model: Schema, Value: Fields
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
        .init(root: self.key, field: self.wrappedValue[keyPath: keyPath])
    }
}

public final class _NestedField<Model, Field>
    where Model: FluentKit.Fields, Field: FieldProtocol
{
    public let root: FieldKey
    public let field: Field
    init(root: FieldKey, field: Field) {
        self.root = root
        self.field = field
    }
}

extension _NestedField: PropertyProtocol {
    public typealias Model = Field.Model
    public typealias Value = Field.Value
}

extension _NestedField: AnyProperty {
    public func input(to input: inout DatabaseInput) {
        self.field.input(to: &input)
    }

    public func output(from output: DatabaseOutput) throws {
        try self.field.output(from: output)
    }

    public func encode(to encoder: Encoder) throws {
        try self.field.encode(to: encoder)
    }

    public func decode(from decoder: Decoder) throws {
        try self.field.decode(from: decoder)
    }
}

extension _NestedField: FieldProtocol {
    public var fieldValue: Field.FieldValue {
        get {
            self.field.fieldValue
        }
        set {
            self.field.fieldValue = newValue
        }
    }

    public typealias FieldValue = Field.FieldValue
}

extension _NestedField: AnyField {
    public var keys: [FieldKey] {
        [self.root] + self.field.keys
    }
}


#warning("TODO: cleanup")
extension NestedFieldProperty: FieldProtocol {
    public typealias FieldValue = Value

    public var fieldValue: Value {
        get {
            self.wrappedValue
        }
        set {
            self.wrappedValue = newValue
        }
    }
}

extension NestedFieldProperty: AnyField {
    public var keys: [FieldKey] {
        [self.key]
    }

    public func input(to input: inout DatabaseInput) {
        if let value = self.value {
            input.values[self.key] = .bind(value)
        }
    }

    public func output(from output: DatabaseOutput) throws {
        self.value = try output.decode(self.key, as: Value.self)
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
