@dynamicMemberLookup
public protocol ModelAlias: _ModelAlias {
    subscript<Field>(
        dynamicMember keyPath: KeyPath<Model, Field>
    ) -> AliasedField<Self, Field>
        where Field.Model == Model
    { get }

    subscript<Value>(
        dynamicMember keyPath: KeyPath<Model, Value>
    ) -> Value { get }
}

// https://bugs.swift.org/browse/SR-12256
public protocol _ModelAlias: Schema {
    associatedtype Model: FluentKit.Model
    static var name: String { get }
    var model: Model { get }
}

extension _ModelAlias {
    public static var schema: String {
        Model.schema
    }

    public static var alias: String? {
        self.name
    }
}

extension ModelAlias {
    public subscript<Field>(
        dynamicMember keyPath: KeyPath<Model, Field>
    ) -> AliasedField<Self, Field>
        where Field.Model == Model
    {
        .init(field: self.model[keyPath: keyPath])
    }

    public subscript<Value>(
        dynamicMember keyPath: KeyPath<Model, Value>
    ) -> Value {
        self.model[keyPath: keyPath]
    }

    public var properties: [AnyProperty] {
        self.model.properties
    }
}

public final class AliasedField<Alias, Field>
    where Alias: ModelAlias, Field: FieldProtocol
{
    public let field: Field
    init(field: Field) {
        self.field = field
    }
}

extension AliasedField: PropertyProtocol {
    public typealias Model = Alias
    public typealias Value = Field.Value

    public var value: Field.Value? {
        get {
            self.field.value
        }
        set {
            self.field.value = newValue
        }
    }
}

extension AliasedField: AnyProperty {
    public var path: [FieldKey] {
        self.field.path
    }

    public var nested: [AnyProperty] {
        self.field.nested
    }

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

extension AliasedField: FieldProtocol { }
