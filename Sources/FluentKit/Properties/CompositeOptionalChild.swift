import NIOCore

extension Model {
    /// A convenience alias for ``CompositeOptionalChildProperty``. It is strongly recommended that callers use this
    /// alias rather than referencing ``CompositeOptionalChildProperty`` directly whenever possible.
    public typealias CompositeOptionalChild<To> = CompositeOptionalChildProperty<Self, To>
        where To: FluentKit.Model, Self.IDValue: Fields
}

/// Declares an optional one-to-one relation between the referenced ("child") model and the referencing
/// ("parent") model, where the parent model specifies its ID with ``CompositeIDProperty``.
///
/// ``CompositeOptionalChildProperty`` serves the same purpose for child models with parents which use
/// `@CompositeID` that ``OptionalChildProperty`` serves for parent models which use `@ID`.
///
/// Unfortunately, while the type of ID used by the child model makes no difference, limitations of Swift's
/// generics syntax make it impractical to support both `@ID`-using and `@CompositeID`-using models as the parent
/// model with a single property type.
///
/// ``CompositeOptionalChildProperty`` cannot reference a ``ParentProperty`` or ``OptionalParentProperty``; use
/// ``OptionalChildProperty`` instead.
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
///     @CompositeParent(prefix: "meta") var metaTable: TableMetadata
///     @CompositeOptionalChild(for: \.$metaTable) var realizedTable: TableMetadata?
///     // ...
///
///     struct CreateTableMigration: AsyncMigration {
///         func prepare(on database: Database) async throws {
///             try await database.schema(TableMetadata.schema)
///                 .field("table_schema", .string, .required)
///                 .field("table_name", .string, .required)
///                 .compositeIdentifier(over: ["table_schema", "table_name"])
///                 .field("meta_table_schema", .string, .required)
///                 .field("meta_table_name", .string, .required)
///                 .foreignKey(["meta_table_schema", "meta_table_name"], references: TableMetadata.schema, ["table_schema", "table_name"])
///                 // ...
///                 .create()
///         }
///     }
/// }
/// ```
@propertyWrapper
public final class CompositeOptionalChildProperty<From, To>
    where From: Model, To: Model, From.IDValue: Fields
{
    public typealias Key = CompositeRelationParentKey<From, To>
    
    public let parentKey: Key
    var idValue: From.IDValue?

    public var value: To??

    public init(for parentKey: KeyPath<To, To.CompositeParent<From>>) {
        self.parentKey = .required(parentKey)
    }
    
    public init(for parentKey: KeyPath<To, To.CompositeOptionalParent<From>>) {
        self.parentKey = .optional(parentKey)
    }

    public var wrappedValue: To? {
        get {
            guard let value = self.value else {
                fatalError("Child relation not eager loaded, use $ prefix to access: \(self.name)")
            }
            return value
        }
        set {
            fatalError("Child relation \(self.name) is get-only.")
        }
    }

    public var projectedValue: CompositeOptionalChildProperty<From, To> { self }
    
    public var fromId: From.IDValue? {
        get { return self.idValue }
        set { self.idValue = newValue }
    }

    public func query(on database: Database) -> QueryBuilder<To> {
        guard let id = self.idValue else {
            fatalError("Cannot query child relation \(self.name) from unsaved model.")
        }

        /// We route the value through an instance of the child model's parent property to ensure the
        /// correct prefix and strategy for this specific relation are applied to the filter keys, then
        /// apply filters for each property of the ID to a query builder for the child model. See the
        /// implementation of `ParentKey.queryFilterIds(_:in:)` for the implementation, and the
        /// documentation for ``QueryFilterInput`` for details of how the actual filtering works.
        return self.parentKey.queryFilterIds([id], in: To.query(on: database))
    }
}

extension CompositeOptionalChildProperty: CustomStringConvertible {
    public var description: String { self.name }
}

extension CompositeOptionalChildProperty: AnyProperty { }

extension CompositeOptionalChildProperty: Property {
    public typealias Model = From
    public typealias Value = To?
}

extension CompositeOptionalChildProperty: AnyDatabaseProperty {
    public var keys: [FieldKey] { [] }
    public func input(to input: DatabaseInput) {}
    public func output(from output: DatabaseOutput) throws {
        if From.IDValue.keys.reduce(true, { $0 && output.contains($1) }) { // don't output unless all keys are present
            self.idValue = From.IDValue()
            try self.idValue!.output(from: output)
        }
    }
}

extension CompositeOptionalChildProperty: AnyCodableProperty {
    public func encode(to encoder: Encoder) throws {
        if let value = self.value {
            var container = encoder.singleValueContainer()
            try container.encode(value)
        }
    }
    public func decode(from decoder: Decoder) throws {}
    public var skipPropertyEncoding: Bool { self.value == nil }
}

extension CompositeOptionalChildProperty: Relation {
    public var name: String { "CompositeOptionalChild<\(From.self), \(To.self)>(for: \(self.parentKey))" }
    public func load(on database: Database) -> EventLoopFuture<Void> { self.query(on: database).first().map { self.value = $0 } }
}

extension CompositeOptionalChildProperty: EagerLoadable {
    public static func eagerLoad<Builder>(_ relationKey: KeyPath<From, CompositeOptionalChildProperty<From, To>>, to builder: Builder)
        where Builder : EagerLoadBuilder, From == Builder.Model
    {
        self.eagerLoad(relationKey, withDeleted: false, to: builder)
    }
    
    public static func eagerLoad<Builder>(_ relationKey: KeyPath<From, From.CompositeOptionalChild<To>>, withDeleted: Bool, to builder: Builder)
        where Builder: EagerLoadBuilder, Builder.Model == From
    {
        let loader = CompositeOptionalChildEagerLoader(relationKey: relationKey, withDeleted: withDeleted)
        builder.add(loader: loader)
    }


    public static func eagerLoad<Loader, Builder>(_ loader: Loader, through: KeyPath<From, From.CompositeOptionalChild<To>>, to builder: Builder)
        where Loader: EagerLoader, Loader.Model == To, Builder: EagerLoadBuilder, Builder.Model == From
    {
        let loader = ThroughCompositeOptionalChildEagerLoader(relationKey: through, loader: loader)
        builder.add(loader: loader)
    }
}

private struct CompositeOptionalChildEagerLoader<From, To>: EagerLoader
    where From: Model, To: Model, From.IDValue: Fields
{
    let relationKey: KeyPath<From, From.CompositeOptionalChild<To>>
    let withDeleted: Bool

    func run(models: [From], on database: Database) -> EventLoopFuture<Void> {
        let ids = Set(models.map(\.id!))
        let parentKey = From()[keyPath: self.relationKey].parentKey
        let builder = To.query(on: database)
        
        builder.group(.or) { query in
            _ = parentKey.queryFilterIds(ids, in: query)
        }
        if (self.withDeleted) {
            builder.withDeleted()
        }
        return builder.all().map {
            let indexedResults = Dictionary(grouping: $0, by: { parentKey.referencedId(in: $0)! })
            
            for model in models {
                model[keyPath: self.relationKey].value = indexedResults[model[keyPath: self.relationKey].idValue!]?.first
            }
        }
    }
}

private struct ThroughCompositeOptionalChildEagerLoader<From, Through, Loader>: EagerLoader
    where From: Model, From.IDValue: Fields, Loader: EagerLoader, Loader.Model == Through
{
    let relationKey: KeyPath<From, From.CompositeOptionalChild<Through>>
    let loader: Loader

    func run(models: [From], on database: Database) -> EventLoopFuture<Void> {
        return self.loader.run(models: models.compactMap { $0[keyPath: self.relationKey].value! }, on: database)
    }
}
