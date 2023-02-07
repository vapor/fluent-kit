extension QueryBuilder {
    // MARK: - High-level joins

    /// Performs a join with a condition containing a single expression not
    @discardableResult
    public func join<Foreign>(
        _ foreign: Foreign.Type,
        on filter: ComplexJoinFilter,
        method: DatabaseQuery.Join.Method = .inner
    ) -> Self where Foreign: Schema {
        self.join(Foreign.self, [filter.filter], method: method)
    }

    /// Performs a join with a condition containing multiple subexpressions.
    @discardableResult
    public func join<Foreign>(
        _ foreign: Foreign.Type,
        on filter: ComplexJoinFilterGroup,
        method: DatabaseQuery.Join.Method = .inner
    ) -> Self
        where Foreign: Schema
    {
        self.join(Foreign.self, filter.filters.map(\.filter), method: method)
    }

    // MARK: - Fundamental join methods
    
    /// `.join(Foreign.self, filters, method: method)`
    ///
    /// Joins against `Foreign` with the specified method and using the given filter(s) as the join condition.
    @discardableResult
    public func join<Foreign>(
        _ foreign: Foreign.Type,
        _ filters: [DatabaseQuery.Filter],
        method: DatabaseQuery.Join.Method = .inner
    ) -> Self
        where Foreign: Schema
    {
        self.join(Foreign.self, on: .advancedJoin(schema: Foreign.schema, space: Foreign.space, alias: Foreign.alias, method, filters: filters))
    }
    
    /// `.join(Foreign.self, on: databaseJoin)`
    ///
    /// Joins against `Foreign` using the given join description.
    ///
    /// In debug builds, the join is checked (when possible) to verify that it corresponds correctly to the provided
    /// model type; an assertion failure occurs if there is a mismatch. This check is not performed in release builds.
    ///
    /// - Warning: The space, schema, and alias specified by the join description _must_ match the `space`, `schema`,
    ///   and `alias` properties of the provided `Foreign` type. Violation of this rule will cause runtime errors in
    ///   most kinds of queries, and incorrect data may be returned from queries which do run.
    ///
    /// - Tip: If you find that the requirements of your join are incompatible with this rule, you're probably trying
    ///   to do something that's too complex for Fluent's API to accomodate. The recommended solution is to bypass
    ///   Fluent and execute the desired query more directly, either via SQLKit when working with an SQL database, or
    ///   via MongoKitten if using MongoDB.
    @discardableResult
    public func join<Foreign>(
        _ foreign: Foreign.Type,
        on join: DatabaseQuery.Join
    ) -> Self
        where Foreign: Schema
    {
        #if DEBUG
        switch join {
        case let .join(jschema, jalias, _, _, _):
            assert(jschema == Foreign.schema && jalias == Foreign.alias, "Join specification does not match provided Model type \(Foreign.self)")
        case let .extendedJoin(jschema, jspace, jalias, _, _, _), let .advancedJoin(jschema, jspace, jalias, _, _):
            assert(jspace == Foreign.space && jschema == Foreign.schema && jalias == Foreign.alias, "Join specification does not match provided Model type \(Foreign.self)")
        case.custom(_):
            break // We can't validate custom joins
        }
        #endif

        self.models.append(Foreign.self)
        self.query.joins.append(join)
        return self
    }

}

// MARK: Local == Foreign

public func == <Foreign, ForeignField, Local, LocalField>(
    lhs: KeyPath<Local, LocalField>, rhs: KeyPath<Foreign, ForeignField>
) -> ComplexJoinFilter where
    Foreign: Schema, Local: Schema, ForeignField: QueryableProperty, LocalField: QueryableProperty,
    ForeignField.Value == LocalField.Value
{
    .init(lhs, .equal, rhs)
}

public func == <Foreign, ForeignField, Local, LocalField>(
    lhs: KeyPath<Local, LocalField>, rhs: KeyPath<Foreign, ForeignField>
) -> ComplexJoinFilter where
    Foreign: Schema, Local: Schema, ForeignField: QueryableProperty, LocalField: QueryableProperty,
    ForeignField.Value == LocalField.Value?
{
    .init(lhs, .equal, rhs)
}

public func == <Foreign, ForeignField, Local, LocalField>(
    lhs: KeyPath<Local, LocalField>, rhs: KeyPath<Foreign, ForeignField>
) -> ComplexJoinFilter where
    Foreign: Schema, Local: Schema, ForeignField: QueryableProperty, LocalField: QueryableProperty,
    ForeignField.Value? == LocalField.Value
{
    .init(lhs, .equal, rhs)
}

// MARK: Local != Foreign

public func != <Foreign, ForeignField, Local, LocalField>(
    lhs: KeyPath<Local, LocalField>, rhs: KeyPath<Foreign, ForeignField>
) -> ComplexJoinFilter where
    Foreign: Schema, Local: Schema, ForeignField: QueryableProperty, LocalField: QueryableProperty,
    ForeignField.Value == LocalField.Value
{
    .init(lhs, .notEqual, rhs)
}

public func != <Foreign, ForeignField, Local, LocalField>(
    lhs: KeyPath<Local, LocalField>, rhs: KeyPath<Foreign, ForeignField>
) -> ComplexJoinFilter where
    Foreign: Schema, Local: Schema, ForeignField: QueryableProperty, LocalField: QueryableProperty,
    ForeignField.Value == LocalField.Value?
{
    .init(lhs, .notEqual, rhs)
}

public func != <Foreign, ForeignField, Local, LocalField>(
    lhs: KeyPath<Local, LocalField>, rhs: KeyPath<Foreign, ForeignField>
) -> ComplexJoinFilter where
    Foreign: Schema, Local: Schema, ForeignField: QueryableProperty, LocalField: QueryableProperty,
    ForeignField.Value? == LocalField.Value
{
    .init(lhs, .notEqual, rhs)
}

// MARK: Filter && combinator

/// a ==/!= b && c ==/!= d
public func && (lhs: ComplexJoinFilter, rhs: ComplexJoinFilter) -> ComplexJoinFilterGroup {
    .init(filters: [lhs, rhs])
}

/// (a == b && c != d) && e != f
public func && (lhs: ComplexJoinFilterGroup, rhs: ComplexJoinFilter) -> ComplexJoinFilterGroup {
    .init(filters: lhs.filters + [rhs])
}

// e != f && (a == b && c != d)
public func && (lhs: ComplexJoinFilter, rhs: ComplexJoinFilterGroup) -> ComplexJoinFilterGroup {
    .init(filters: [lhs] + rhs.filters)
}

// MARK: - Struct definitions

/// This wrapper type allows the compiler to better constrain the overload set for global operators, reducing
/// compile times and avoiding "this expression is too complex..." errors.
public struct ComplexJoinFilter {
    let filter: DatabaseQuery.Filter
    
    init(filter: DatabaseQuery.Filter) {
        self.filter = filter
    }
    
    init<Left, LField, Right, RField>(
        _ lhs: KeyPath<Left, LField>, _ method: DatabaseQuery.Filter.Method, _ rhs: KeyPath<Right, RField>
    ) where Left: Schema, Right: Schema, LField: QueryableProperty, RField: QueryableProperty, LField.Value == RField.Value {
        self.init(filter: .field(
            .extendedPath(Left.path(for: lhs), schema: Left.schemaOrAlias, space: Left.spaceIfNotAliased),
            method,
            .extendedPath(Right.path(for: rhs), schema: Right.schemaOrAlias, space: Right.spaceIfNotAliased)
        ))
    }

    init<Left, LField, Right, RField>(
        _ lhs: KeyPath<Left, LField>, _ method: DatabaseQuery.Filter.Method, _ rhs: KeyPath<Right, RField>
    ) where Left: Schema, Right: Schema, LField: QueryableProperty, RField: QueryableProperty, LField.Value? == RField.Value {
        self.init(filter: .field(
            .extendedPath(Left.path(for: lhs), schema: Left.schemaOrAlias, space: Left.spaceIfNotAliased),
            method,
            .extendedPath(Right.path(for: rhs), schema: Right.schemaOrAlias, space: Right.spaceIfNotAliased)
        ))
    }

    init<Left, LField, Right, RField>(
        _ lhs: KeyPath<Left, LField>, _ method: DatabaseQuery.Filter.Method, _ rhs: KeyPath<Right, RField>
    ) where Left: Schema, Right: Schema, LField: QueryableProperty, RField: QueryableProperty, LField.Value == RField.Value? {
        self.init(filter: .field(
            .extendedPath(Left.path(for: lhs), schema: Left.schemaOrAlias, space: Left.spaceIfNotAliased),
            method,
            .extendedPath(Right.path(for: rhs), schema: Right.schemaOrAlias, space: Right.spaceIfNotAliased)
        ))
    }
}

/// This wrapper type allows the compiler to better constrain the overload set for global operators, reducing
/// compile times and avoiding "this expression is too complex..." errors.
public struct ComplexJoinFilterGroup {
    let filters: [ComplexJoinFilter]
}

// MARK: - Legacy join filter type support

extension QueryBuilder {
    @discardableResult
    public func join<Foreign, Local>(
        _ local: Local.Type,
        _ foreign: Foreign.Type,
        on filter: DatabaseQuery.Join
    ) -> Self
        where Local: Schema, Foreign: Schema
    {
        self.join(Foreign.self, on: filter)
    }
    
    @discardableResult
    public func join<Foreign, Local, Value>(
        _ foreign: Foreign.Type,
        on filter: JoinFilter<Foreign, Local, Value>,
        method: DatabaseQuery.Join.Method = .inner
    ) -> Self
        where Foreign: Schema, Local: Schema
    {
        self.join(Foreign.self, on: ComplexJoinFilter(filter: .field(
            .extendedPath(filter.foreign, schema: Foreign.schemaOrAlias, space: Foreign.spaceIfNotAliased),
            .equal,
            .extendedPath(filter.local, schema: Local.schemaOrAlias, space: Local.spaceIfNotAliased)
        )), method: method)
    }
}

public struct JoinFilter<Foreign, Local, Value>
    where Foreign: Fields, Local: Fields, Value: Codable
{
    let foreign: [FieldKey]
    let local: [FieldKey]
}
