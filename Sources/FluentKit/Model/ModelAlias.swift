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
        .init(key: Model.key(for: keyPath))
    }

    public subscript<Value>(
        dynamicMember keyPath: KeyPath<Model, Value>
    ) -> Value {
        self.model[keyPath: keyPath]
    }

    public var fields: [String: AnyField] {
        self.model.fields
    }
}

public struct AliasedField<Alias, Field>
    where Alias: ModelAlias, Field: QueryField
{
    public let key: FieldKey
}

extension AliasedField: QueryField {
    public var path: [FieldKey] {
        [self.key]
    }

    public var wrappedValue: Field.Value {
        fatalError()
    }

    public typealias Model = Alias
    public typealias Value = Field.Value
}
