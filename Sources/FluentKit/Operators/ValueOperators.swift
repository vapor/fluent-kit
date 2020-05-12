extension QueryBuilder {
    @discardableResult
    public func filter(_ filter: ModelValueFilter<Model>) -> Self {
        self.filter(Model.self, filter)
    }

    @discardableResult
    public func filter<Joined>(
        _ schema: Joined.Type,
        _ filter: ModelValueFilter<Joined>
    ) -> Self
        where Joined: Schema
    {
        self.filter(
            .path(filter.path, schema: Joined.schemaOrAlias),
            filter.method,
            filter.value
        )
    }
}

// MARK: Field.Value

public func == <Model, Field>(lhs: KeyPath<Model, Field>, rhs: Field.Value) -> ModelValueFilter<Model>
    where Model: Fields, Field: QueryableProperty
{
    lhs == Field.queryValue(rhs)
}

public func != <Model, Field>(lhs: KeyPath<Model, Field>, rhs: Field.Value) -> ModelValueFilter<Model>
    where Model: Fields, Field: QueryableProperty
{
    lhs != Field.queryValue(rhs)
}

public func >= <Model, Field>(lhs: KeyPath<Model, Field>, rhs: Field.Value) -> ModelValueFilter<Model>
    where Model: Fields, Field: QueryableProperty
{
    lhs >= Field.queryValue(rhs)
}

public func > <Model, Field>(lhs: KeyPath<Model, Field>, rhs: Field.Value) -> ModelValueFilter<Model>
    where Model: Fields, Field: QueryableProperty
{
    lhs > Field.queryValue(rhs)
}

public func < <Model, Field>(lhs: KeyPath<Model, Field>, rhs: Field.Value) -> ModelValueFilter<Model>
    where Model: Fields, Field: QueryableProperty
{
    lhs < Field.queryValue(rhs)
}

public func <= <Model, Field>(lhs: KeyPath<Model, Field>, rhs: Field.Value) -> ModelValueFilter<Model>
    where Model: Fields, Field: QueryableProperty
{
    lhs <= Field.queryValue(rhs)
}

// MARK: DatabaseQuery.Value

public func == <Model, Field>(lhs: KeyPath<Model, Field>, rhs: DatabaseQuery.Value) -> ModelValueFilter<Model>
    where Model: Fields, Field: QueryableProperty
{
    .init(lhs, .equal, rhs)
}

public func != <Model, Field>(lhs: KeyPath<Model, Field>, rhs: DatabaseQuery.Value) -> ModelValueFilter<Model>
    where Model: Fields, Field: QueryableProperty
{
    .init(lhs, .notEqual, rhs)
}

public func >= <Model, Field>(lhs: KeyPath<Model, Field>, rhs: DatabaseQuery.Value) -> ModelValueFilter<Model>
    where Model: Fields, Field: QueryableProperty
{
    .init(lhs, .greaterThanOrEqual, rhs)
}

public func > <Model, Field>(lhs: KeyPath<Model, Field>, rhs: DatabaseQuery.Value) -> ModelValueFilter<Model>
    where Model: Fields, Field: QueryableProperty
{
    .init(lhs, .greaterThan, rhs)
}

public func < <Model, Field>(lhs: KeyPath<Model, Field>, rhs: DatabaseQuery.Value) -> ModelValueFilter<Model>
    where Model: Fields, Field: QueryableProperty
{
    .init(lhs, .lessThan, rhs)
}

public func <= <Model, Field>(lhs: KeyPath<Model, Field>, rhs: DatabaseQuery.Value) -> ModelValueFilter<Model>
    where Model: Fields, Field: QueryableProperty
{
    .init(lhs, .lessThanOrEqual, rhs)
}

public struct ModelValueFilter<Model> where Model: Fields {
    init<Field>(
        _ lhs: KeyPath<Model, Field>,
        _ method: DatabaseQuery.Filter.Method,
        _ rhs: DatabaseQuery.Value
    )
        where Field: QueryableProperty
    {
        self.path = Model.path(for: lhs)
        self.method = method
        self.value = rhs
    }

    let path: [FieldKey]
    let method: DatabaseQuery.Filter.Method
    let value: DatabaseQuery.Value
}
