public protocol Schema: Fields {
    static var schema: String { get }
    static var alias: String? { get }
}

extension Schema {
    public static var schemaOrAlias: String {
        self.alias ?? self.schema
    }
}

@dynamicMemberLookup
public protocol ModelAlias: Schema {
    associatedtype Model: FluentKit.Model
    var model: Model { get }

    subscript<Field>(
        dynamicMember keyPath: KeyPath<Model, Field>
    ) -> AliasedField<Self, Field> { get }

    subscript<Value>(
        dynamicMember keyPath: KeyPath<Model, Value>
    ) -> Value { get }
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

extension ModelAlias {
    public subscript<Field>(
        dynamicMember keyPath: KeyPath<Model, Field>
    ) -> AliasedField<Self, Field> {
        .init(key: Model.key(for: keyPath))
    }

    public subscript<Value>(
        dynamicMember keyPath: KeyPath<Model, Value>
    ) -> Value {
        self.model[keyPath: keyPath]
    }

    public var fields: [String: Any] {
        self.model.fields
    }
}

public protocol Model: Schema, AnyModel {
    associatedtype IDValue: Codable, Hashable
    var id: IDValue? { get set }
}

extension Model {
    public static var alias: String? { nil }
}

extension AnyModel {
    public static var keys: [FieldKey] {
        Self().keys
    }
}

extension Model {
    public static func query(on database: Database) -> QueryBuilder<Self> {
        .init(database: database)
    }

    public static func find(
        _ id: Self.IDValue?,
        on database: Database
    ) -> EventLoopFuture<Self?> {
        guard let id = id else {
            return database.eventLoop.makeSucceededFuture(nil)
        }
        return Self.query(on: database)
            .filter(\._$id == id)
            .first()
    }

    public func requireID() throws -> IDValue {
        guard let id = self.id else {
            throw FluentError.idRequired
        }
        return id
    }

    // MARK: Internal

    var _$id: ID<IDValue> {
        self.anyID as! ID<IDValue>
    }
}
