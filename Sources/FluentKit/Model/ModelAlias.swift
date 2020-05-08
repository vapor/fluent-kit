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

@dynamicMemberLookup
public final class AliasedField<Alias, Field>
    where Alias: ModelAlias, Field: Property
{
    public let field: Field
    init(field: Field) {
        self.field = field
    }

    public subscript<Nested>(
        dynamicMember keyPath: KeyPath<Field, Nested>
    ) -> AliasedField<Alias, Nested> {
        .init(field: self.field[keyPath: keyPath])
    }
}

extension AliasedField: Property {
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

extension AliasedField: AnyQueryableProperty where Field: AnyQueryableProperty {
    public var path: [FieldKey] {
        self.field.path
    }
}

extension AliasedField: QueryableProperty where Field: QueryableProperty { }
