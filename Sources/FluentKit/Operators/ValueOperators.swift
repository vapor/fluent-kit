extension QueryBuilder {
    @discardableResult
    public func filter(_ filter: ModelValueFilter<Model>) -> Self {
        return self.filter(
            .field(path: filter.path, schema: Model.schema, alias: nil),
            filter.method,
            filter.value
        )
    }

    @discardableResult
    public func filter<Joined>(_ alias: Joined.Type, _ filter: ModelValueFilter<Joined>) -> Self
        where Joined: FluentKit.Model
    {
        return self.filter(
            .field(path: filter.path, schema: Joined.schema, alias: nil),
            filter.method,
            filter.value
        )
    }

    @discardableResult
    public func filter<Alias>(_ alias: Alias.Type, _ filter: ModelValueFilter<Alias.Model>) -> Self
        where Alias: ModelAlias
    {
        return self.filter(
            .field(path: filter.path, schema: Alias.alias, alias: nil),
            filter.method,
            filter.value
        )
    }
}

// MARK: Field.Value

public func == <Model, Field>(lhs: KeyPath<Model, Field>, rhs: Field.Value) -> ModelValueFilter<Model>
    where Model: FluentKit.Model, Field: FieldProtocol
{
    lhs == .bind(rhs)
}

public func != <Model, Field>(lhs: KeyPath<Model, Field>, rhs: Field.Value) -> ModelValueFilter<Model>
    where Model: FluentKit.Model, Field: FieldProtocol
{
    lhs != .bind(rhs)
}

public func >= <Model, Field>(lhs: KeyPath<Model, Field>, rhs: Field.Value) -> ModelValueFilter<Model>
    where Model: FluentKit.Model, Field: FieldProtocol
{
    lhs >= .bind(rhs)
}

public func > <Model, Field>(lhs: KeyPath<Model, Field>, rhs: Field.Value) -> ModelValueFilter<Model>
    where Model: FluentKit.Model, Field: FieldProtocol
{
    lhs > .bind(rhs)
}

public func < <Model, Field>(lhs: KeyPath<Model, Field>, rhs: Field.Value) -> ModelValueFilter<Model>
    where Model: FluentKit.Model, Field: FieldProtocol
{
    lhs < .bind(rhs)
}

public func <= <Model, Field>(lhs: KeyPath<Model, Field>, rhs: Field.Value) -> ModelValueFilter<Model>
    where Model: FluentKit.Model, Field: FieldProtocol
{
    lhs <= .bind(rhs)
}

// MARK: DatabaseQuery.Value

public func == <Model, Field>(lhs: KeyPath<Model, Field>, rhs: DatabaseQuery.Value) -> ModelValueFilter<Model>
    where Model: FluentKit.Model, Field: FieldProtocol
{
    .init(lhs, .equal, rhs)
}

public func != <Model, Field>(lhs: KeyPath<Model, Field>, rhs: DatabaseQuery.Value) -> ModelValueFilter<Model>
    where Model: FluentKit.Model, Field: FieldProtocol
{
    .init(lhs, .notEqual, rhs)
}

public func >= <Model, Field>(lhs: KeyPath<Model, Field>, rhs: DatabaseQuery.Value) -> ModelValueFilter<Model>
    where Model: FluentKit.Model, Field: FieldProtocol
{
    .init(lhs, .greaterThanOrEqual, rhs)
}

public func > <Model, Field>(lhs: KeyPath<Model, Field>, rhs: DatabaseQuery.Value) -> ModelValueFilter<Model>
    where Model: FluentKit.Model, Field: FieldProtocol
{
    .init(lhs, .greaterThan, rhs)
}

public func < <Model, Field>(lhs: KeyPath<Model, Field>, rhs: DatabaseQuery.Value) -> ModelValueFilter<Model>
    where Model: FluentKit.Model, Field: FieldProtocol
{
    .init(lhs, .lessThan, rhs)
}

public func <= <Model, Field>(lhs: KeyPath<Model, Field>, rhs: DatabaseQuery.Value) -> ModelValueFilter<Model>
    where Model: FluentKit.Model, Field: FieldProtocol
{
    .init(lhs, .lessThanOrEqual, rhs)
}

public struct ModelValueFilter<Model> where Model: FluentKit.Model {
    init<Field>(
        _ lhs: KeyPath<Model, Field>,
        _ method: DatabaseQuery.Filter.Method,
        _ rhs: DatabaseQuery.Value
    )
        where Field: FieldProtocol
    {
        self.path = Model.init()[keyPath: lhs].path
        self.method = method
        self.value = rhs
    }

    let path: [FieldKey]
    let method: DatabaseQuery.Filter.Method
    let value: DatabaseQuery.Value
}
