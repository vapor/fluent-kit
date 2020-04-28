// MARK: Field.Value

public func ~~ <Model, Field, Values>(lhs: KeyPath<Model, Field>, rhs: Values) -> ModelValueFilter<Model>
    where Model: FluentKit.Model,
        Field: FieldProtocol,
        Values: Collection,
        Values.Element == Field.FilterValue
{
    lhs ~~ .array(rhs.map { Field.queryValue($0) })
}

public func ~~ <Model, Field, Values>(lhs: KeyPath<Model, Field>, rhs: Values) -> ModelValueFilter<Model>
    where Model: FluentKit.Model,
        Field: FieldProtocol,
        Field.FilterValue: OptionalType,
        Field.FilterValue.Wrapped: Codable,
        Values: Collection,
        Values.Element == Field.FilterValue.Wrapped
{
    lhs ~~ .array(rhs.map { .bind($0) })
}

public func !~ <Model, Field, Values>(lhs: KeyPath<Model, Field>, rhs: Values) -> ModelValueFilter<Model>
    where Model: FluentKit.Model,
        Field: FieldProtocol,
        Values: Collection,
        Values.Element == Field.FilterValue
{
    lhs !~ .array(rhs.map { Field.queryValue($0) })
}

public func !~ <Model, Field, Values>(lhs: KeyPath<Model, Field>, rhs: Values) -> ModelValueFilter<Model>
    where Model: FluentKit.Model,
        Field: FieldProtocol,
        Field.FilterValue: OptionalType,
        Field.FilterValue.Wrapped: Codable,
        Values: Collection,
        Values.Element == Field.FilterValue.Wrapped
{
    lhs !~ .array(rhs.map { .bind($0) })
}

// MARK: DatabaseQuery.Value

public func ~~ <Model, Field>(lhs: KeyPath<Model, Field>, rhs: DatabaseQuery.Value) -> ModelValueFilter<Model>
    where Model: FluentKit.Model, Field: FieldProtocol
{
    .init(lhs, .subset(inverse: false), rhs)
}

public func !~ <Model, Field>(lhs: KeyPath<Model, Field>, rhs: DatabaseQuery.Value) -> ModelValueFilter<Model>
    where Model: FluentKit.Model, Field: FieldProtocol
{
    .init(lhs, .subset(inverse: true), rhs)
}
