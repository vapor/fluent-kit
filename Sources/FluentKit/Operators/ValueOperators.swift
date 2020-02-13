// MARK: Field.Value

public func == <Model, Field>(lhs: KeyPath<Model, Field>, rhs: Field.Value) -> ModelValueFilter<Model>
    where Model: FluentKit.Model, Field: FieldRepresentable
{
    lhs == .bind(rhs)
}

public func != <Model, Field>(lhs: KeyPath<Model, Field>, rhs: Field.Value) -> ModelValueFilter<Model>
    where Model: FluentKit.Model, Field: FieldRepresentable
{
    lhs != .bind(rhs)
}

public func >= <Model, Field>(lhs: KeyPath<Model, Field>, rhs: Field.Value) -> ModelValueFilter<Model>
    where Model: FluentKit.Model, Field: FieldRepresentable
{
    lhs >= .bind(rhs)
}

public func > <Model, Field>(lhs: KeyPath<Model, Field>, rhs: Field.Value) -> ModelValueFilter<Model>
    where Model: FluentKit.Model, Field: FieldRepresentable
{
    lhs > .bind(rhs)
}

public func < <Model, Field>(lhs: KeyPath<Model, Field>, rhs: Field.Value) -> ModelValueFilter<Model>
    where Model: FluentKit.Model, Field: FieldRepresentable
{
    lhs < .bind(rhs)
}

public func <= <Model, Field>(lhs: KeyPath<Model, Field>, rhs: Field.Value) -> ModelValueFilter<Model>
    where Model: FluentKit.Model, Field: FieldRepresentable
{
    lhs <= .bind(rhs)
}

// MARK: DatabaseQuery.Value

public func == <Model, Field>(lhs: KeyPath<Model, Field>, rhs: DatabaseQuery.Value) -> ModelValueFilter<Model>
    where Model: FluentKit.Model, Field: FieldRepresentable
{
    .init(lhs, .equal, rhs)
}

public func != <Model, Field>(lhs: KeyPath<Model, Field>, rhs: DatabaseQuery.Value) -> ModelValueFilter<Model>
    where Model: FluentKit.Model, Field: FieldRepresentable
{
    .init(lhs, .notEqual, rhs)
}

public func >= <Model, Field>(lhs: KeyPath<Model, Field>, rhs: DatabaseQuery.Value) -> ModelValueFilter<Model>
    where Model: FluentKit.Model, Field: FieldRepresentable
{
    .init(lhs, .greaterThanOrEqual, rhs)
}

public func > <Model, Field>(lhs: KeyPath<Model, Field>, rhs: DatabaseQuery.Value) -> ModelValueFilter<Model>
    where Model: FluentKit.Model, Field: FieldRepresentable
{
    .init(lhs, .greaterThan, rhs)
}

public func < <Model, Field>(lhs: KeyPath<Model, Field>, rhs: DatabaseQuery.Value) -> ModelValueFilter<Model>
    where Model: FluentKit.Model, Field: FieldRepresentable
{
    .init(lhs, .lessThan, rhs)
}

public func <= <Model, Field>(lhs: KeyPath<Model, Field>, rhs: DatabaseQuery.Value) -> ModelValueFilter<Model>
    where Model: FluentKit.Model, Field: FieldRepresentable
{
    .init(lhs, .lessThanOrEqual, rhs)
}

public struct ModelValueFilter<Model> where Model: FluentKit.Model {
    init<Field>(
        _ lhs: KeyPath<Model, Field>,
        _ method: DatabaseQuery.Filter.Method,
        _ rhs: DatabaseQuery.Value
    )
        where Field: FieldRepresentable
    {
        self.path = [Model.init()[keyPath: lhs].field.key]
        self.method = method
        self.value = rhs
    }

    let path: [String]
    let method: DatabaseQuery.Filter.Method
    let value: DatabaseQuery.Value
}
