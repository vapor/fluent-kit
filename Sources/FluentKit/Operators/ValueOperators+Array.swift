// MARK: Field.Value

public func ~~ <Model, Field>(lhs: KeyPath<Model, Field>, rhs: [Field.Value]) -> ModelValueFilter<Model>
    where Model: FluentKit.Model, Field: FieldRepresentable
{
    lhs ~~ .array(rhs.map { .bind($0) })
}

public func !~ <Model, Field>(lhs: KeyPath<Model, Field>, rhs: [Field.Value]) -> ModelValueFilter<Model>
    where Model: FluentKit.Model, Field: FieldRepresentable
{
    lhs !~ .array(rhs.map { .bind($0) })
}

// MARK: DatabaseQuery.Value

public func ~~ <Model, Field>(lhs: KeyPath<Model, Field>, rhs: DatabaseQuery.Value) -> ModelValueFilter<Model>
    where Model: FluentKit.Model, Field: FieldRepresentable
{
    .init(lhs, .subset(inverse: false), rhs)
}

public func !~ <Model, Field>(lhs: KeyPath<Model, Field>, rhs: DatabaseQuery.Value) -> ModelValueFilter<Model>
    where Model: FluentKit.Model, Field: FieldRepresentable
{
    .init(lhs, .subset(inverse: true), rhs)
}
