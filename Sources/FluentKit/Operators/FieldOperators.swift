public func == <Left, Right, Field>(lhs: KeyPath<Left, Field>, rhs: KeyPath<Right, Field>) -> ModelFieldFilter<Left, Right>
    where Left: FluentKit.Model, Right: FluentKit.Model, Field: FieldRepresentable
{
    .init(lhs, .equal, rhs)
}

public func != <Left, Right, Field>(lhs: KeyPath<Left, Field>, rhs: KeyPath<Right, Field>) -> ModelFieldFilter<Left, Right>
    where Left: FluentKit.Model, Right: FluentKit.Model, Field: FieldRepresentable
{
    .init(lhs, .notEqual, rhs)
}

public func >= <Left, Right, Field>(lhs: KeyPath<Left, Field>, rhs: KeyPath<Right, Field>) -> ModelFieldFilter<Left, Right>
    where Left: FluentKit.Model, Right: FluentKit.Model, Field: FieldRepresentable
{
    .init(lhs, .greaterThanOrEqual, rhs)
}

public func > <Left, Right, Field>(lhs: KeyPath<Left, Field>, rhs: KeyPath<Right, Field>) -> ModelFieldFilter<Left, Right>
    where Left: FluentKit.Model, Right: FluentKit.Model, Field: FieldRepresentable
{
    .init(lhs, .greaterThan, rhs)
}

public func < <Left, Right, Field>(lhs: KeyPath<Left, Field>, rhs: KeyPath<Right, Field>) -> ModelFieldFilter<Left, Right>
    where Left: FluentKit.Model, Right: FluentKit.Model, Field: FieldRepresentable
{
    .init(lhs, .lessThan, rhs)
}

public func <= <Left, Right, Field>(lhs: KeyPath<Left, Field>, rhs: KeyPath<Right, Field>) -> ModelFieldFilter<Left, Right>
    where Left: FluentKit.Model, Right: FluentKit.Model, Field: FieldRepresentable
{
    .init(lhs, .lessThanOrEqual, rhs)
}

public func ~= <Left, Right, Field>(lhs: KeyPath<Left, Field>, rhs: KeyPath<Right, Field>) -> ModelFieldFilter<Left, Right>
    where Left: FluentKit.Model, Right: FluentKit.Model, Field: FieldRepresentable, Field.Value: CustomStringConvertible
{
    .init(lhs, .contains(inverse: false, .suffix), rhs)
}

public func ~~ <Left, Right, Field>(lhs: KeyPath<Left, Field>, rhs: KeyPath<Right, Field>) -> ModelFieldFilter<Left, Right>
    where Left: FluentKit.Model, Right: FluentKit.Model, Field: FieldRepresentable, Field.Value: CustomStringConvertible
{
    .init(lhs, .contains(inverse: false, .anywhere), rhs)
}

public func =~ <Left, Right, Field>(lhs: KeyPath<Left, Field>, rhs: KeyPath<Right, Field>) -> ModelFieldFilter<Left, Right>
    where Left: FluentKit.Model, Right: FluentKit.Model, Field: FieldRepresentable, Field.Value: CustomStringConvertible
{
    .init(lhs, .contains(inverse: false, .prefix), rhs)
}

public func !~= <Left, Right, Field>(lhs: KeyPath<Left, Field>, rhs: KeyPath<Right, Field>) -> ModelFieldFilter<Left, Right>
    where Left: FluentKit.Model, Right: FluentKit.Model, Field: FieldRepresentable, Field.Value: CustomStringConvertible
{
    .init(lhs, .contains(inverse: true, .suffix), rhs)
}

public func !~ <Left, Right, Field>(lhs: KeyPath<Left, Field>, rhs: KeyPath<Right, Field>) -> ModelFieldFilter<Left, Right>
    where Left: FluentKit.Model, Right: FluentKit.Model, Field: FieldRepresentable, Field.Value: CustomStringConvertible
{
    .init(lhs, .contains(inverse: true, .anywhere), rhs)
}

public func !=~ <Left, Right, Field>(lhs: KeyPath<Left, Field>, rhs: KeyPath<Right, Field>) -> ModelFieldFilter<Left, Right>
    where Left: FluentKit.Model, Right: FluentKit.Model, Field: FieldRepresentable, Field.Value: CustomStringConvertible
{
    .init(lhs, .contains(inverse: true, .prefix), rhs)
}

public struct ModelFieldFilter<Left, Right>
    where Left: FluentKit.Model, Right: FluentKit.Model
{
    init<Field>(
        _ lhs: KeyPath<Left, Field>,
        _ method: DatabaseQuery.Filter.Method,
        _ rhs: KeyPath<Right, Field>
    )
        where Field: FieldRepresentable
    {
        self.lhsPath = [Left.init()[keyPath: lhs].field.key]
        self.method = method
        self.rhsPath = [Right.init()[keyPath: rhs].field.key]
    }

    let lhsPath: [String]
    let method: DatabaseQuery.Filter.Method
    let rhsPath: [String]
}
