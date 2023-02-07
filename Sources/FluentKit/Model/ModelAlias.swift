/// Describes a model whose schema has an alias.
///
/// The ``ModelAlias`` protocol allows creating model types which are identical to
/// an existing ``Model`` except that any Fluent query referencing the aliased type
/// will use the provided alias name to refer to the model's ``schema`` rather than
/// the one specified by the model type. This allows, for example, referencing the
/// same model more than once within the same query, such as when joining to a
/// a parent model twice in the same query when the original model has multiple
/// parent references of the same type.
///
/// Types conforming to this protocol can be used anywhere the original model's type
/// may be referenced. The alias type will mirror the ``space`` and ``schema`` of the
/// original model, and provide its name for the ``alias`` property, affecting the
/// result of the ``Schema/schemaOrAlias`` accessor. This accessor is used anywhere
/// that a schema name that has been aliased may appear in place of the original.
///
/// Example:
///
/// ````
/// final class Team: Model {
///     static                   let schema = "teams"
///     @ID(   key: .id)         var id: UUID?
///     @Field(key: "name")      var name: String
///     init() {}
/// }
/// final class Match: Model {
///     static                       let schema = "matches"
///     @ID(    key: .id)            var id: UUID?
///     @Parent(key: "home_team_id") var homeTeam: Team
///     @Parent(key: "away_team_id") var awayTeam: Team
///     init() {}
/// }
/// final class HomeTeam: ModelAlias { static let name = "home_teams" ; let model = Team() }
/// final class AwayTeam: ModelAlias { static let name = "away_teams" ; let model = Team() }
///
/// for match in try await Match.query(on: self.database)
///     .join(HomeTeam.self, on: \Match.$homeTeam.$id == \HomeTeam.$id)
///     .join(AwayTeam.self, on: \Match.$awayTeam.$id == \AwayTeam.$id)
///     .all()
/// {
///     self.database.logger.debug("home: \(try match.joined(HomeTeam.self))")
///     self.database.logger.debug("away: \(try match.joined(AwayTeam.self))")
/// }
/// ````
@dynamicMemberLookup
public protocol ModelAlias: Schema {
    /// The model type to be aliased.
    associatedtype Model: FluentKit.Model
    
    /// The actual alias name to be used in place of `Model.schema`.
    static var name: String { get }
    
    /// An instance of the orignal model type. Holds returned data from lookups, and
    /// is used as a data source for CRUD operations.
    ///
    /// When applying an alias to data that will be returned from a query, set this
    /// property to `Model.init()` in the alias type's initializer.
    ///
    /// When applying an alias to data that will updated or removed, or for creation
    /// from pre-filled data, set this property to an existing model object.
    var model: Model { get }

    /// `@dynamicMemberLookup` support. The implementation of this subscript is provided
    /// automatically and should not be overriden by conforming types. See
    /// ``ModelAlias/subscript(dynamicMember:)-8hc9u`` for details.
    subscript<Field>(dynamicMember keyPath: KeyPath<Self.Model, Field>) -> AliasedField<Self, Field>
        where Field.Model == Self.Model
    { get }

    /// `@dynamicMemberLookup` support. The implementation of this subscript is provided
    /// automatically and should not be overriden by conforming types. See
    /// ``ModelAlias/subscript(dynamicMember:)-9fej6`` for details.
    subscript<Value>(dynamicMember keyPath: KeyPath<Model, Value>) -> Value { get }
}

extension ModelAlias {
    /// An alias's ``space`` is always that of the original Model.
    public static var space: String? { Model.space }
    
    /// An alias's ``schema`` is always that of the original Model. This is the full, unaliased
    /// schema name , and must remain so even for the aliased model type in order to correctly
    /// specify for the database driver what identifier the alias applies to.
    public static var schema: String { Model.schema }

    /// The aliased name, which stands in for the actual schema name. ``ModelAlias`` strictly
    /// enforces the same constraint most dialects of SQL do for aliasing syntax: That the
    /// original schema name may only appear at points where aliasing is declared, and becomes
    /// syntactically incorrect usage should it appear in any other part of the query. In effect,
    /// the alias becomes the only name by which the model type may be referenced.
    public static var alias: String? {
        self.name
    }

    /// An `@dynamicMemberLookup` subscript which access to the projected values of individual
    /// properties of `self.model` without having to actually add `.model` to each usage. The
    /// ``AliasedField`` helper type further ensures that the alias propagates correctly through
    /// further helpers and subsysems, most particularly `.with()` closures in a query for eager-
    /// loading.
    ///
    /// The presence of ``subscript(dynamicMember:)-19xu5`` and this subscript together enables
    /// nearly transparent use of a ``ModelAlias`` type as if it were the underlying ``Model`` type.
    ///
    /// Example:
    ///
    /// ```swift
    /// let alias = HomeTeam()
    /// print(alias.$id.exists) // false
    /// ```
    public subscript<Field>(dynamicMember keyPath: KeyPath<Model, Field>) -> AliasedField<Self, Field>
        where Field.Model == Self.Model
    {
        .init(field: self.model[keyPath: keyPath])
    }

    /// An `@dynamicMemberLookup` subscript which enables direct access to the values of individual
    /// properties of `self.model` without having to actually add `.model` to each usage.
    ///
    /// The presence of ``subscript(dynamicMember:)-64vdz`` and this subscript together enables
    /// nearly transparent use of a ``ModelAlias`` type as if it were the underlying ``Model`` type.
    ///
    /// Example:
    ///
    /// ```swift
    /// let alias = HomeTeam()
    /// print(alias.name) // fatalError("Cannot access field before it is initialized or fetched: name")
    /// ```
    public subscript<Value>(dynamicMember keyPath: KeyPath<Model, Value>) -> Value {
        self.model[keyPath: keyPath]
    }

    /// A passthrough to ``Fields/properties-7z9l1``, as invoked on `self.model`. This is a deliberate shadowing
    /// override of ``Fields/properties-7z9l1`` for the alias type itself, required to allow projected property
    /// values (i.e. instances of ``AliasedField``) to correctly behave as the properties they provide
    /// automatic access to. Without this override, the "parent" implementation would always return an empty
    /// array, as the alias type does not itself make direct use of any of the property wrapper types.
    public var properties: [AnyProperty] { self.model.properties }
}

/// Provides support for `@dynamicMemberLookup` to continue descending through arbitrary
/// levels of nested projected properties values.
@dynamicMemberLookup
public final class AliasedField<Alias, Field>
    where Alias: ModelAlias, Field: Property, Alias.Model == Field.Model
{
    public let field: Field

    fileprivate init(field: Field) { self.field = field }

    public subscript<Nested>(dynamicMember keyPath: KeyPath<Field, Nested>) -> AliasedField<Alias, Nested> {
        .init(field: self.field[keyPath: keyPath])
    }
}

/// Forwarded ``AnyProperty`` conformance for ``AliasedField``.
extension AliasedField: AnyProperty {
    public static var anyValueType: Any.Type { Field.anyValueType }
    public var anyValue: Any? { self.field.anyValue }
}

/// Forwarded ``Property`` conformance for ``AliasedField``.
extension AliasedField: Property {
    /// N.B.: The definition of the aliased field's ``Model`` as the alias rather than the original ``Model`` is
    /// the core purpose of ``AliasedField`` and of chained projected values; without this redefinition, the
    /// `.joined(...)` helper would not work correctly for aliases.
    public typealias Model = Alias
    public typealias Value = Field.Value

    public var value: Field.Value? {
        get { self.field.value }
        set { self.field.value = newValue }
    }
}

/// Conditionally forwarded ``AnyQueryableProperty`` conformance for ``AliasedField``.
extension AliasedField: AnyQueryableProperty where Field: AnyQueryableProperty {
    public func queryableValue() -> DatabaseQuery.Value? { self.field.queryableValue() }
    public var path: [FieldKey] { self.field.path }
}

/// Conditionally forwarded ``QueryableProperty`` confromance for ``AliasedField``.
extension AliasedField: QueryableProperty where Field: QueryableProperty {
    public static func queryValue(_ value: Field.Value) -> DatabaseQuery.Value { Field.queryValue(value) }
}

/// Conditionally forwarded ``AnyQueryAddressableProperty`` conformance for ``AliasedField``.
extension AliasedField: AnyQueryAddressableProperty where Field: AnyQueryAddressableProperty {
    public var queryablePath: [FieldKey] { self.field.queryablePath }
    public var anyQueryableProperty: AnyQueryableProperty { self.field.anyQueryableProperty }
}

/// Conditionally forwarded ``QueryAddressableProperty`` conformance for ``AliasedField``.
///
/// N.B.: It might seem at a glance as if this conformance could be used to propagate the model
/// alias rather than requiring all this tedious boilerpolate - however, this perception is
/// misleading. A query-addressable property is either also a queryable property (in which case
/// it must always address itself) _or_ addresses a single queryable property which shall be
/// substituted in its place at all points of usage - there is by design nothing which could
/// carry the propagated alias.
extension AliasedField: QueryAddressableProperty where Field: QueryAddressableProperty {
    public var queryableProperty: Field.QueryablePropertyType { self.field.queryableProperty }
}

/// N.B. Forwarding ``AnyCodableProperty`` conformance for ``AliasedField`` would be ineffective, and
/// also wrong even if it did function. Encoding and decoding of properties (and by extension the
/// ``Fields`` which contain them) uses the Swift names of the properties as coding keys, not database
/// names; the namespacing a model alias introduces does not apply to there.

/// N.B. In the same vein, forwarding ``AnyDatabaseProperty`` conformance would also be undesirable.
/// The correct application of aliases to schemas during `input()` and `output()` operations is already
/// handled explcitly, and with correct handling of nesting, long before the individual property
/// conformances come into play. Which means that trying to account for the alias at this level would
/// end up mangling the correct fully-qualified property identifier quite badly.
