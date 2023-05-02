import NIOCore

extension Model {
    /// A convenience alias for ``CompositeParentProperty``. It is strongly recommended that callers use this
    /// alias rather than referencing ``CompositeParentProperty`` directly whenever possible.
    public typealias CompositeParent<To> = CompositeParentProperty<Self, To>
        where To: Model, To.IDValue: Fields
}

/// Declares a one-to-many relation between the referenced ("parent") model and the referencing ("child") model,
/// where the parent model specifies its ID with ``CompositeIDProperty``.
///
/// ``CompositeParentProperty`` serves the same purpose for parent models which use `@CompositeID`
/// that ``ParentProperty`` serves for parent models which use `@ID`.
///
/// Unfortunately, while the type of ID used by the child model makes no difference, limitations of Swift's
/// generics syntax make it impractical to support both `@ID`-using and `@CompositeID`-using models as the parent
/// model with a single property type. A similar limitation applies in the opposite direction for
/// ``ChildrenProperty`` and ``OptionalChildProperty``.
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
///     // ...
/// }
///
/// final class ForeignKeyMetadata: Model {
///     static let schema = "foreign_key_metadata"
///
///     @ID(custom: "constraint_name") var id: String?
///     @CompositeParent(prefix: "referencing") var referencingTable: TableMetadata
///     @CompositeParent(prefix: "referenced") var referencedTable: TableMetadata
///     // ...
///
///     struct CreateTableMigration: AsyncMigration {
///         func prepare(on database: Database) async throws {
///             try await database.schema(ForeignKeyMetadata.schema)
///                 .field("constraint_name", .string, .required, .identifier(auto: false))
///                 .field("referencing_table_schema", .string, .required)
///                 .field("referencing_table_name", .string, .required)
///                 .foreignKey(["referencing_table_schema", "referencing_table_name"], references: TableMetadata.schema, ["table_schema", "table_name"])
///                 .field("referenced_table_schema", .string, .required)
///                 .field("referenced_table_name", .string, .required)
///                 .foreignKey(["referenced_table_schema", "referenced_table_name"], references: TableMetadata.schema, ["table_schema", "table_name"])
///                 // ...
///                 .create()
///         }
///     }
/// }
/// ```
@propertyWrapper @dynamicMemberLookup
public final class CompositeParentProperty<From, To>
    where From: Model, To: Model, To.IDValue: Fields
{
    public let prefix: FieldKey
    public let prefixingStrategy: KeyPrefixingStrategy
    public var id: To.IDValue
    public var value: To?

    public var wrappedValue: To {
        get {
            guard let value = self.value else {
                fatalError("Parent relation not eager loaded, use $ prefix to access: \(self.name)")
            }
            return value
        }
        set { fatalError("use $ prefix to access \(self.name)") }
    }

    public var projectedValue: CompositeParentProperty<From, To> { self }
    
    /// Configure a ``CompositeParentProperty`` with a key prefix and prefix strategy.
    ///
    /// - Parameters:
    ///   - prefix: A prefix to be applied to the key of each individual field of the referenced model's `IDValue`.
    ///   - strategy: The strategy to use when applying prefixes to keys. ``KeyPrefixingStrategy/snakeCase`` is
    ///     the default.
    public init(prefix: FieldKey, strategy: KeyPrefixingStrategy = .snakeCase) {
        self.id = .init()
        self.prefix = prefix
        self.prefixingStrategy = strategy
    }

    public func query(on database: Database) -> QueryBuilder<To> {
        return To.query(on: database).group(.and) { self.id.input(to: QueryFilterInput(builder: $0)) }
    }

    public subscript<Nested>(dynamicMember keyPath: KeyPath<To.IDValue, Nested>) -> Nested
        where Nested: Property
    {
        self.id[keyPath: keyPath]
    }
}

extension CompositeParentProperty: CustomStringConvertible {
    public var description: String {
        self.name
    }
}

extension CompositeParentProperty: Relation {
    public var name: String {
        "CompositeParent<\(From.self), \(To.self)>(prefix: \(self.prefix), strategy: \(self.prefixingStrategy))"
    }
    
    public func load(on database: Database) -> EventLoopFuture<Void> {
        self.query(on: database)
            .first()
            .map {
                self.value = $0
            }
    }
}

extension CompositeParentProperty: AnyProperty {}

extension CompositeParentProperty: Property {
    public typealias Model = From
    public typealias Value = To
}

extension CompositeParentProperty: AnyDatabaseProperty {
    public var keys: [FieldKey] {
        To.IDValue.keys.map {
            self.prefixingStrategy.apply(prefix: self.prefix, to: $0)
        }
    }
    
    public func input(to input: DatabaseInput) {
        self.id.input(to: input.prefixed(by: self.prefix, using: self.prefixingStrategy))
    }
    
    public func output(from output: DatabaseOutput) throws {
        try self.id.output(from: output.prefixed(by: self.prefix, using: self.prefixingStrategy))
    }
}

extension CompositeParentProperty: AnyCodableProperty {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        if let value = self.value {
            try container.encode(value)
        } else {
            try container.encode(["id": self.id])
        }
    }

    public func decode(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: SomeCodingKey.self)
        self.id = try container.decode(To.IDValue.self, forKey: .init(stringValue: "id"))
    }
}

extension CompositeParentProperty: EagerLoadable {
    public static func eagerLoad<Builder>(_ relationKey: KeyPath<From, CompositeParentProperty<From, To>>, to builder: Builder)
    where Builder : EagerLoadBuilder, From == Builder.Model
    {
        self.eagerLoad(relationKey, withDeleted: false, to: builder)
    }
    
    public static func eagerLoad<Builder>(_ relationKey: KeyPath<From, From.CompositeParent<To>>, withDeleted: Bool, to builder: Builder)
        where Builder: EagerLoadBuilder, Builder.Model == From
    {
        builder.add(loader: CompositeParentEagerLoader(relationKey: relationKey, withDeleted: withDeleted))
    }

    public static func eagerLoad<Loader, Builder>(_ loader: Loader, through: KeyPath<From, From.CompositeParent<To>>, to builder: Builder)
        where Loader: EagerLoader, Loader.Model == To, Builder: EagerLoadBuilder, Builder.Model == From
    {
        builder.add(loader: ThroughCompositeParentEagerLoader(relationKey: through, loader: loader))
    }
}

private struct CompositeParentEagerLoader<From, To>: EagerLoader
    where From: Model, To: Model, To.IDValue: Fields
{
    let relationKey: KeyPath<From, From.CompositeParent<To>>
    let withDeleted: Bool
    
    func run(models: [From], on database: Database) -> EventLoopFuture<Void> {
        let sets = Dictionary(grouping: models, by: { $0[keyPath: self.relationKey].id })

        let builder = To.query(on: database)
            .group(.or) {
                _ = sets.keys.reduce($0) { query, id in query.group(.and) { id.input(to: QueryFilterInput(builder: $0)) } }
            }
        if (self.withDeleted) {
            builder.withDeleted()
        }
        return builder.all()
            .flatMapThrowing {
                let parents = Dictionary(uniqueKeysWithValues: $0.map { ($0.id!, $0) })

                for (parentId, models) in sets {
                    guard let parent = parents[parentId] else {
                        database.logger.debug(
                            "Missing parent model in eager-load lookup results.",
                            metadata: ["parent": "\(To.self)", "id": "\(parentId)"]
                        )
                        throw FluentError.missingParentError(keyPath: self.relationKey, id: parentId)
                    }
                    models.forEach {
                        $0[keyPath: self.relationKey].value = parent
                    }
                }
            }
    }
}

private struct ThroughCompositeParentEagerLoader<From, Through, Loader>: EagerLoader
    where From: Model, Loader: EagerLoader, Loader.Model == Through, Through.IDValue: Fields
{
    let relationKey: KeyPath<From, From.CompositeParent<Through>>
    let loader: Loader
    
    func run(models: [From], on database: Database) -> EventLoopFuture<Void> {
        self.loader.run(models: models.map {
            $0[keyPath: self.relationKey].value!
        }, on: database)
    }
}
