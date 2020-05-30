// MARK: Field.Value

public func ~~ <Model, Field, Values>(lhs: KeyPath<Model, Field>, rhs: Values) -> ModelValueFilter<Model>
    where Model: FluentKit.Model,
        Field: QueryableProperty,
        Values: Collection,
        Values.Element == Field.Value
{
    lhs ~~ .array(rhs.map { Field.queryValue($0) })
}

public func ~~ <Model, Field, Values>(lhs: KeyPath<Model, Field>, rhs: Values) -> ModelValueFilter<Model>
    where Model: FluentKit.Model,
        Field: QueryableProperty,
        Field.Value: OptionalType,
        Field.Value.Wrapped: Codable,
        Values: Collection,
        Values.Element == Field.Value.Wrapped
{
    lhs ~~ .array(rhs.map { .bind($0) })
}

public func !~ <Model, Field, Values>(lhs: KeyPath<Model, Field>, rhs: Values) -> ModelValueFilter<Model>
    where Model: FluentKit.Model,
        Field: QueryableProperty,
        Values: Collection,
        Values.Element == Field.Value
{
    lhs !~ .array(rhs.map { Field.queryValue($0) })
}

public func !~ <Model, Field, Values>(lhs: KeyPath<Model, Field>, rhs: Values) -> ModelValueFilter<Model>
    where Model: FluentKit.Model,
        Field: QueryableProperty,
        Field.Value: OptionalType,
        Field.Value.Wrapped: Codable,
        Values: Collection,
        Values.Element == Field.Value.Wrapped
{
    lhs !~ .array(rhs.map { .bind($0) })
}

// MARK: DatabaseQuery.Value

public func ~~ <Model, Field>(lhs: KeyPath<Model, Field>, rhs: DatabaseQuery.Value) -> ModelValueFilter<Model>
    where Model: FluentKit.Model, Field: QueryableProperty
{
    .init(lhs, .subset(inverse: false), rhs)
}

public func !~ <Model, Field>(lhs: KeyPath<Model, Field>, rhs: DatabaseQuery.Value) -> ModelValueFilter<Model>
    where Model: FluentKit.Model, Field: QueryableProperty
{
    .init(lhs, .subset(inverse: true), rhs)
}
