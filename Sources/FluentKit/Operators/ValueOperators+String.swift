// MARK: Field.Value

public func ~= <Model, Field>(lhs: KeyPath<Model, Field>, rhs: String) -> ModelValueFilter<Model>
    where
        Model: FluentKit.Model,
        Field: QueryableProperty,
        Field.Value == String
{
    lhs ~= Field.queryValue(rhs)
}

public func ~= <Model, Field>(lhs: KeyPath<Model, Field>, rhs: String) -> ModelValueFilter<Model>
    where
        Model: FluentKit.Model,
        Field: QueryableProperty,
        Field.Value: OptionalType,
        Field.Value.Wrapped == String
{
    lhs ~= Field.queryValue(.init(rhs))
}

public func ~~ <Model, Field>(lhs: KeyPath<Model, Field>, rhs: String) -> ModelValueFilter<Model>
    where
        Model: FluentKit.Model,
        Field: QueryableProperty,
        Field.Value == String
{
    lhs ~~ Field.queryValue(rhs)
}

public func ~~ <Model, Field>(lhs: KeyPath<Model, Field>, rhs: String) -> ModelValueFilter<Model>
    where
        Model: FluentKit.Model,
        Field: QueryableProperty,
        Field.Value: OptionalType,
        Field.Value.Wrapped == String
{
    lhs ~~ Field.queryValue(.init(rhs))
}

public func =~ <Model, Field>(lhs: KeyPath<Model, Field>, rhs: String) -> ModelValueFilter<Model>
    where
        Model: FluentKit.Model,
        Field: QueryableProperty,
        Field.Value == String
{
    lhs =~ Field.queryValue(rhs)
}

public func =~ <Model, Field>(lhs: KeyPath<Model, Field>, rhs: String) -> ModelValueFilter<Model>
    where
        Model: FluentKit.Model,
        Field: QueryableProperty,
        Field.Value: OptionalType,
        Field.Value.Wrapped == String
{
    lhs =~ Field.queryValue(.init(rhs))
}

public func !~= <Model, Field>(lhs: KeyPath<Model, Field>, rhs: String) -> ModelValueFilter<Model>
    where
        Model: FluentKit.Model,
        Field: QueryableProperty,
        Field.Value == String
{
    lhs !~= Field.queryValue(rhs)
}

public func !~= <Model, Field>(lhs: KeyPath<Model, Field>, rhs: String) -> ModelValueFilter<Model>
    where
        Model: FluentKit.Model,
        Field: QueryableProperty,
        Field.Value: OptionalType,
        Field.Value.Wrapped == String
{
    lhs !~= Field.queryValue(.init(rhs))
}

public func !~ <Model, Field>(lhs: KeyPath<Model, Field>, rhs: String) -> ModelValueFilter<Model>
    where
        Model: FluentKit.Model,
        Field: QueryableProperty,
        Field.Value == String
{
    lhs !~ Field.queryValue(rhs)
}

public func !~ <Model, Field>(lhs: KeyPath<Model, Field>, rhs: String) -> ModelValueFilter<Model>
    where
        Model: FluentKit.Model,
        Field: QueryableProperty,
        Field.Value: OptionalType,
        Field.Value.Wrapped == String
{
    lhs !~ Field.queryValue(.init(rhs))
}

public func !=~ <Model, Field>(lhs: KeyPath<Model, Field>, rhs: String) -> ModelValueFilter<Model>
    where
        Model: FluentKit.Model,
        Field: QueryableProperty,
        Field.Value == String
{
    lhs !=~ Field.queryValue(rhs)
}

public func !=~ <Model, Field>(lhs: KeyPath<Model, Field>, rhs: String) -> ModelValueFilter<Model>
    where
        Model: FluentKit.Model,
        Field: QueryableProperty,
        Field.Value: OptionalType,
        Field.Value.Wrapped == String
{
    lhs !=~ Field.queryValue(.init(rhs))
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

public func ~= <Model, Field>(lhs: KeyPath<Model, Field>, rhs: DatabaseQuery.Value) -> ModelValueFilter<Model>
    where
        Model: FluentKit.Model,
        Field: QueryableProperty,
        Field.Value: OptionalType,
        Field.Value.Wrapped: CustomStringConvertible
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

public func ~~ <Model, Field>(lhs: KeyPath<Model, Field>, rhs: DatabaseQuery.Value) -> ModelValueFilter<Model>
    where
        Model: FluentKit.Model,
        Field: QueryableProperty,
        Field.Value: OptionalType,
        Field.Value.Wrapped: CustomStringConvertible
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

public func =~ <Model, Field>(lhs: KeyPath<Model, Field>, rhs: DatabaseQuery.Value) -> ModelValueFilter<Model>
    where
        Model: FluentKit.Model,
        Field: QueryableProperty,
        Field.Value: OptionalType,
        Field.Value.Wrapped: CustomStringConvertible
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

public func !~= <Model, Field>(lhs: KeyPath<Model, Field>, rhs: DatabaseQuery.Value) -> ModelValueFilter<Model>
    where
        Model: FluentKit.Model,
        Field: QueryableProperty,
        Field.Value: OptionalType,
        Field.Value.Wrapped: CustomStringConvertible
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

public func !~ <Model, Field>(lhs: KeyPath<Model, Field>, rhs: DatabaseQuery.Value) -> ModelValueFilter<Model>
    where
        Model: FluentKit.Model,
        Field: QueryableProperty,
        Field.Value: OptionalType,
        Field.Value.Wrapped: CustomStringConvertible
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

public func !=~ <Model, Field>(lhs: KeyPath<Model, Field>, rhs: DatabaseQuery.Value) -> ModelValueFilter<Model>
    where
        Model: FluentKit.Model,
        Field: QueryableProperty,
        Field.Value: OptionalType,
        Field.Value.Wrapped: CustomStringConvertible
{
    .init(lhs, .contains(inverse: true, .prefix), rhs)
}
