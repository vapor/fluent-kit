// MARK: Field.Value

public func ~= <Model, Field>(lhs: KeyPath<Model, Field>, rhs: Field.Value) -> ModelValueFilter<Model>
    where
        Model: FluentKit.Model,
        Field: QueryableProperty,
        Field.Value: CustomStringConvertible
{
    lhs ~= Field.queryValue(rhs)
}

public func ~~ <Model, Field>(lhs: KeyPath<Model, Field>, rhs: Field.Value) -> ModelValueFilter<Model>
    where
        Model: FluentKit.Model,
        Field: QueryableProperty,
        Field.Value: CustomStringConvertible
{
    lhs ~~ Field.queryValue(rhs)
}

public func =~ <Model, Field>(lhs: KeyPath<Model, Field>, rhs: Field.Value) -> ModelValueFilter<Model>
    where
        Model: FluentKit.Model,
        Field: QueryableProperty,
        Field.Value: CustomStringConvertible
{
    lhs =~ Field.queryValue(rhs)
}

public func !~= <Model, Field>(lhs: KeyPath<Model, Field>, rhs: Field.Value) -> ModelValueFilter<Model>
    where
        Model: FluentKit.Model,
        Field: QueryableProperty,
        Field.Value: CustomStringConvertible
{
    lhs !~= Field.queryValue(rhs)
}

public func !~ <Model, Field>(lhs: KeyPath<Model, Field>, rhs: Field.Value) -> ModelValueFilter<Model>
    where
        Model: FluentKit.Model,
        Field: QueryableProperty,
        Field.Value: CustomStringConvertible
{
    lhs !~ Field.queryValue(rhs)
}

public func !=~ <Model, Field>(lhs: KeyPath<Model, Field>, rhs: Field.Value) -> ModelValueFilter<Model>
    where
        Model: FluentKit.Model,
        Field: QueryableProperty,
        Field.Value: CustomStringConvertible
{
    lhs !=~ Field.queryValue(rhs)
}

// MARK: DatabaseQuery.Value

public func ~= <Model, Field>(lhs: KeyPath<Model, Field>, rhs: DatabaseQuery.Value) -> ModelValueFilter<Model>
    where
        Model: FluentKit.Model,
        Field: QueryableProperty,
        Field.Value: CustomStringConvertible
{
    .init(lhs, .contains(inverse: false, .suffix), rhs)
}

public func ~~ <Model, Field>(lhs: KeyPath<Model, Field>, rhs: DatabaseQuery.Value) -> ModelValueFilter<Model>
    where
        Model: FluentKit.Model,
        Field: QueryableProperty,
        Field.Value: CustomStringConvertible
{
    .init(lhs, .contains(inverse: false, .anywhere), rhs)
}

public func =~ <Model, Field>(lhs: KeyPath<Model, Field>, rhs: DatabaseQuery.Value) -> ModelValueFilter<Model>
    where
        Model: FluentKit.Model,
        Field: QueryableProperty,
        Field.Value: CustomStringConvertible
{
    .init(lhs, .contains(inverse: false, .prefix), rhs)
}

public func !~= <Model, Field>(lhs: KeyPath<Model, Field>, rhs: DatabaseQuery.Value) -> ModelValueFilter<Model>
    where
        Model: FluentKit.Model,
        Field: QueryableProperty,
        Field.Value: CustomStringConvertible
{
    .init(lhs, .contains(inverse: true, .suffix), rhs)
}

public func !~ <Model, Field>(lhs: KeyPath<Model, Field>, rhs: DatabaseQuery.Value) -> ModelValueFilter<Model>
    where
        Model: FluentKit.Model,
        Field: QueryableProperty,
        Field.Value: CustomStringConvertible
{
    .init(lhs, .contains(inverse: true, .anywhere), rhs)
}

public func !=~ <Model, Field>(lhs: KeyPath<Model, Field>, rhs: DatabaseQuery.Value) -> ModelValueFilter<Model>
    where
        Model: FluentKit.Model,
        Field: QueryableProperty,
        Field.Value: CustomStringConvertible
{
    .init(lhs, .contains(inverse: true, .prefix), rhs)
}
