extension Fields {
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
    ) -> _CompoundField<Value, Field>
        where Field: FieldProtocol,
            Field.Model == Value
    {
        .init(prefix: self.prefix, field: self.wrappedValue[keyPath: keyPath])
    }
}

#warning("TODO: is this right")
extension CompoundFieldProperty: FieldProtocol {
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

extension CompoundFieldProperty: AnyField {
    public var keys: [FieldKey] {
        Value.keys.map {
            .prefixed(self.prefix, $0)
        }
    }

    public func input(to input: inout DatabaseInput) {
        if let value = self.value {
            value.input.values.forEach { (name, value) in
                input.values[.prefixed(self.prefix, name)] = value
            }
        }
    }

    public func output(from output: DatabaseOutput) throws {
        let value = Value()
        try value.output(from: output.prefixed(by: self.prefix))
        self.value = value
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

public final class _CompoundField<Model, Field>
    where Model: FluentKit.Fields, Field: FieldProtocol
{
    public let prefix: String
    public let field: Field
    init(prefix: String, field: Field) {
        self.prefix = prefix
        self.field = field
    }
}

extension _CompoundField: PropertyProtocol {
    public typealias Model = Field.Model
    public typealias Value = Field.Value
}

extension _CompoundField: AnyProperty {
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

extension _CompoundField: FieldProtocol {
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

extension _CompoundField: AnyField {
    public var keys: [FieldKey] {
        guard !self.field.keys.isEmpty else {
            return []
        }
        var path = self.field.keys
        path[0] = .prefixed(self.prefix, path[0])
        return path
    }
}
