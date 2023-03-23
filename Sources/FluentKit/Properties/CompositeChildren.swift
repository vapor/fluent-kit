import NIOCore

extension Model {
    /// A convenience alias for ``CompositeChildrenProperty``. It is strongly recommended that callers use this
    /// alias rather than referencing ``CompositeChildrenProperty`` directly whenever possible.
    public typealias CompositeChildren<To> = CompositeChildrenProperty<Self, To>
        where To: FluentKit.Model, Self.IDValue: Fields
}

/// Declares a many-to-one relation between the referenced ("child") model and the referencing ("parent") model,
/// where the parent model specifies its ID with ``CompositeIDProperty``.
///
/// ``CompositeChildrenProperty`` serves the same purpose for child models with parents which use `@CompositeID`
/// that ``ChildrenProperty`` serves for parent models which use `@ID`.
///
/// Unfortunately, while the type of ID used by the child model makes no difference, limitations of Swift's
/// generics syntax make it impractical to support both `@ID`-using and `@CompositeID`-using models as the parent
/// model with a single property type.
///
/// ``CompositeChildrenProperty`` cannot reference a ``ParentProperty`` or ``OptionalParentProperty``; use
/// ``ChildrenProperty`` instead.
///
/// Example:
///
/// - Note: This example is somewhat contrived; in reality, this kind of metadata would have much more
///   complex relationships.
///
/// ```
/// final class TableMetadata: Model {
///     static let schema = "table_metadata"
///
///     final class IDValue: Fields, Hashable {
///         @Field(key: "table_schema") var schema: String
///         @Field(key: "table_name")   var name: String
///         init() {}
///         static func ==(lhs: IDValue, rhs: IDValue) -> Bool { lhs.schema == rhs.schema && lhs.name == rhs.name }
///         func hash(into hasher: inout Hasher) { hasher.combine(self.schema); hasher.combine(self.name) }
///     }
///
///     @CompositeID var id: IDValue?
///     @CompositeChildren(for: \.$referencedTable) var referencingForeignKeys: [ForeignKeyMetadata]
///     @CompositeChildren(for: \.$nextCrossReferencedTable) var indirectReferencingForeignKeys: [ForeignKeyMetadata]
///     // ...
/// }
///
/// final class ForeignKeyMetadata: Model {
///     static let schema = "foreign_key_metadata"
///
///     @ID(custom: "constraint_name") var id: String?
///     @CompositeParent(prefix: "referenced") var referencedTable: TableMetadata
///     @CompositeOptionalParent(prefix: "next_xref") var nextCrossReferencedTable: TableMetadata?
///     // ...
///
///     struct CreateTableMigration: AsyncMigration {
///         func prepare(on database: Database) async throws {
///             try await database.schema(ForeignKeyMetadata.schema)
///                 .field("constraint_name", .string, .required, .identifier(auto: false))
///                 .field("referenced_table_schema", .string, .required)
///                 .field("referenced_table_name", .string, .required)
///                 .foreignKey(["referenced_table_schema", "referenced_table_name"], references: TableMetadata.schema, ["table_schema", "table_name"])
///                 .field("next_xref_table_schema", .string)
///                 .field("next_xref_table_name", .string)
///                 .foreignKey(["next_xref_table_schema", "next_xref_table_name"], references: TableMetadata.schema, ["table_schema", "table_name"])
///                 .constraint(.sql(.check(SQLBinaryExpression( // adds a check constraint to ensure that neither field is ever NULL when the other isn't
///                     left: SQLBinaryExpression(left: SQLIdentifier("next_xref_table_schema"), .is, right: SQLLiteral.null),
///                     .equal,
///                     right: SQLBinaryExpression(left: SQLIdentifier("next_xref_table_name"), .is, right: SQLLiteral.null)
///                 ))))
///                 // ...
///                 .create()
///         }
///     }
/// }
/// ```
@propertyWrapper
public final class CompositeChildrenProperty<From, To>
    where From: Model, To: Model, From.IDValue: Fields
{
    public typealias Key = CompositeRelationParentKey<From, To>
        
    public let parentKey: Key
    var idValue: From.IDValue?

    public var value: [To]?

    public init(for parentKey: KeyPath<To, To.CompositeParent<From>>) {
        self.parentKey = .required(parentKey)
    }
    
    public init(for parentKey: KeyPath<To, To.CompositeOptionalParent<From>>) {
        self.parentKey = .optional(parentKey)
    }

    public var wrappedValue: [To] {
        get {
            guard let value = self.value else {
                fatalError("Children relation not eager loaded, use $ prefix to access: \(self.name)")
            }
            return value
        }
        set {
            fatalError("Children relation \(self.name) is get-only.")
        }
    }

    public var projectedValue: CompositeChildrenProperty<From, To> { self }
    
    public var fromId: From.IDValue? {
        get { return self.idValue }
        set { self.idValue = newValue }
    }

    public func query(on database: Database) -> QueryBuilder<To> {
        guard let id = self.idValue else {
            fatalError("Cannot query children relation \(self.name) from unsaved model.")
        }

        /// We route the value through an instance of the child model's parent property to ensure the
        /// correct prefix and strategy for this specific relation are applied to the filter keys, then
        /// apply filters for each property of the ID to a query builder for the child model. See the
        /// implementation of `ParentKey.queryFilterIds(_:in:)` for the implementation, and the
        /// documentation for ``QueryFilterInput`` for details of how the actual filtering works.
        return self.parentKey.queryFilterIds([id], in: To.query(on: database))
    }
}

extension CompositeChildrenProperty: CustomStringConvertible {
    public var description: String { self.name }
}

extension CompositeChildrenProperty: AnyProperty { }

extension CompositeChildrenProperty: Property {
    public typealias Model = From
    public typealias Value = [To]
}

extension CompositeChildrenProperty: AnyDatabaseProperty {
    public var keys: [FieldKey] { [] }
    public func input(to input: DatabaseInput) {}
    public func output(from output: DatabaseOutput) throws {
        if From.IDValue.keys.reduce(true, { $0 && output.contains($1) }) { // don't output unless all keys are present
            self.idValue = From.IDValue()
            try self.idValue!.output(from: output)
        }
    }
}

extension CompositeChildrenProperty: AnyCodableProperty {
    public func encode(to encoder: Encoder) throws {
        if let value = self.value {
            var container = encoder.singleValueContainer()
            try container.encode(value)
        }
    }
    public func decode(from decoder: Decoder) throws {}
    public var skipPropertyEncoding: Bool { self.value == nil }
}

extension CompositeChildrenProperty: Relation {
    public var name: String { "CompositeChildren<\(From.self), \(To.self)>(for: \(self.parentKey))" }
    public func load(on database: Database) -> EventLoopFuture<Void> { self.query(on: database).all().map { self.value = $0 } }
}

extension CompositeChildrenProperty: EagerLoadable {
    public static func eagerLoad<Builder>(_ relationKey: KeyPath<From, CompositeChildrenProperty<From, To>>, to builder: Builder)
        where Builder : EagerLoadBuilder, From == Builder.Model
    {
        self.eagerLoad(relationKey, withDeleted: false, to: builder)
    }
    
    public static func eagerLoad<Builder>(_ relationKey: KeyPath<From, From.CompositeChildren<To>>, withDeleted: Bool, to builder: Builder)
        where Builder: EagerLoadBuilder, Builder.Model == From
    {
        let loader = CompositeChildrenEagerLoader(relationKey: relationKey, withDeleted: withDeleted)
        builder.add(loader: loader)
    }


    public static func eagerLoad<Loader, Builder>(_ loader: Loader, through: KeyPath<From, From.CompositeChildren<To>>, to builder: Builder)
        where Loader: EagerLoader, Loader.Model == To, Builder: EagerLoadBuilder, Builder.Model == From
    {
        let loader = ThroughCompositeChildrenEagerLoader(relationKey: through, loader: loader)
        builder.add(loader: loader)
    }
}

private struct CompositeChildrenEagerLoader<From, To>: EagerLoader
    where From: Model, To: Model, From.IDValue: Fields
{
    let relationKey: KeyPath<From, From.CompositeChildren<To>>
    let withDeleted: Bool

    func run(models: [From], on database: Database) -> EventLoopFuture<Void> {
        let ids = Set(models.map(\.id!))
        let parentKey = From()[keyPath: self.relationKey].parentKey
        let builder = To.query(on: database)
        
        builder.group(.or) { query in
            _ = parentKey.queryFilterIds(ids, in: query)
        }
        
        return builder.all().map {
            let indexedResults = Dictionary(grouping: $0, by: { parentKey.referencedId(in: $0)! })
            
            for model in models {
                model[keyPath: self.relationKey].value = indexedResults[model[keyPath: self.relationKey].idValue!] ?? []
            }
        }
    }
}

private struct ThroughCompositeChildrenEagerLoader<From, Through, Loader>: EagerLoader
    where From: Model, From.IDValue: Fields, Loader: EagerLoader, Loader.Model == Through
{
    let relationKey: KeyPath<From, From.CompositeChildren<Through>>
    let loader: Loader

    func run(models: [From], on database: Database) -> EventLoopFuture<Void> {
        return self.loader.run(models: models.flatMap { $0[keyPath: self.relationKey].value! }, on: database)
    }
}
