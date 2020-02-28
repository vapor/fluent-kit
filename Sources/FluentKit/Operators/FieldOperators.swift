extension QueryBuilder {
    @discardableResult
    public func filter(_ filter: ModelFieldFilter<Model, Model>) -> Self {
        self.filter(
            .path(filter.lhsPath, schema: Model.schema),
            filter.method,
            .path(filter.rhsPath, schema: Model.schema)
        )
    }

    @discardableResult
    public func filter<Left, Right>(_ filter: ModelFieldFilter<Left, Right>) -> Self
        where Left: Schema, Right: Schema
    {
        self.filter(
            .path(filter.lhsPath, schema: Left.schemaOrAlias),
            filter.method,
            .path(filter.rhsPath, schema: Right.schemaOrAlias)
        )
    }
}

public func == <Left, Right, LeftField, RightField>(
    lhs: KeyPath<Left, LeftField>,
    rhs: KeyPath<Right, RightField>
) -> ModelFieldFilter<Left, Right>
    where LeftField.Model == Left,
        LeftField: FieldProtocol,
        RightField.Model == Right,
        RightField: FieldProtocol
{
    .init(lhs, .equal, rhs)
}

public func != <Left, Right, LeftField, RightField>(
    lhs: KeyPath<Left, LeftField>,
    rhs: KeyPath<Right, RightField>
) -> ModelFieldFilter<Left, Right>
    where LeftField.Model == Left,
        LeftField: FieldProtocol,
        RightField.Model == Right,
        RightField: FieldProtocol
{
    .init(lhs, .notEqual, rhs)
}

public func >= <Left, Right, LeftField, RightField>(
    lhs: KeyPath<Left, LeftField>,
    rhs: KeyPath<Right, RightField>
) -> ModelFieldFilter<Left, Right>
    where LeftField.Model == Left,
        LeftField: FieldProtocol,
        RightField.Model == Right,
        RightField: FieldProtocol
{
    .init(lhs, .greaterThanOrEqual, rhs)
}

public func > <Left, Right, LeftField, RightField>(
    lhs: KeyPath<Left, LeftField>,
    rhs: KeyPath<Right, RightField>
) -> ModelFieldFilter<Left, Right>
    where LeftField.Model == Left,
        LeftField: FieldProtocol,
        RightField.Model == Right,
        RightField: FieldProtocol
{
    .init(lhs, .greaterThan, rhs)
}

public func < <Left, Right, LeftField, RightField>(
    lhs: KeyPath<Left, LeftField>,
    rhs: KeyPath<Right, RightField>
) -> ModelFieldFilter<Left, Right>
    where LeftField.Model == Left,
        LeftField: FieldProtocol,
        RightField.Model == Right,
        RightField: FieldProtocol
{
    .init(lhs, .lessThan, rhs)
}

public func <= <Left, Right, LeftField, RightField>(
    lhs: KeyPath<Left, LeftField>,
    rhs: KeyPath<Right, RightField>
) -> ModelFieldFilter<Left, Right>
    where LeftField.Model == Left,
        LeftField: FieldProtocol,
        RightField.Model == Right,
        RightField: FieldProtocol
{
    .init(lhs, .lessThanOrEqual, rhs)
}

public func ~= <Left, Right, LeftField, RightField>(
    lhs: KeyPath<Left, LeftField>,
    rhs: KeyPath<Right, RightField>
) -> ModelFieldFilter<Left, Right>
    where LeftField.Model == Left,
        LeftField: FieldProtocol,
        LeftField.Value: CustomStringConvertible,
        RightField.Model == Right,
        RightField: FieldProtocol,
        RightField.Value: CustomStringConvertible
{
    .init(lhs, .contains(inverse: false, .suffix), rhs)
}

public func ~~ <Left, Right, LeftField, RightField>(
    lhs: KeyPath<Left, LeftField>,
    rhs: KeyPath<Right, RightField>
) -> ModelFieldFilter<Left, Right>
    where LeftField.Model == Left,
        LeftField: FieldProtocol,
        LeftField.Value: CustomStringConvertible,
        RightField.Model == Right,
        RightField: FieldProtocol,
        RightField.Value: CustomStringConvertible
{
    .init(lhs, .contains(inverse: false, .anywhere), rhs)
}

public func =~ <Left, Right, LeftField, RightField>(
    lhs: KeyPath<Left, LeftField>,
    rhs: KeyPath<Right, RightField>
) -> ModelFieldFilter<Left, Right>
    where LeftField.Model == Left,
        LeftField: FieldProtocol,
        LeftField.Value: CustomStringConvertible,
        RightField.Model == Right,
        RightField: FieldProtocol,
        RightField.Value: CustomStringConvertible
{
    .init(lhs, .contains(inverse: false, .prefix), rhs)
}

public func !~= <Left, Right, LeftField, RightField>(
    lhs: KeyPath<Left, LeftField>,
    rhs: KeyPath<Right, RightField>
) -> ModelFieldFilter<Left, Right>
    where LeftField.Model == Left,
        LeftField: FieldProtocol,
        LeftField.Value: CustomStringConvertible,
        RightField.Model == Right,
        RightField: FieldProtocol,
        RightField.Value: CustomStringConvertible
{
    .init(lhs, .contains(inverse: true, .suffix), rhs)
}

public func !~ <Left, Right, LeftField, RightField>(
    lhs: KeyPath<Left, LeftField>,
    rhs: KeyPath<Right, RightField>
) -> ModelFieldFilter<Left, Right>
    where LeftField.Model == Left,
        LeftField: FieldProtocol,
        LeftField.Value: CustomStringConvertible,
        RightField.Model == Right,
        RightField: FieldProtocol,
        RightField.Value: CustomStringConvertible
{
    .init(lhs, .contains(inverse: true, .anywhere), rhs)
}

public func !=~ <Left, Right, LeftField, RightField>(
    lhs: KeyPath<Left, LeftField>,
    rhs: KeyPath<Right, RightField>
) -> ModelFieldFilter<Left, Right>
    where LeftField.Model == Left,
        LeftField: FieldProtocol,
        LeftField.Value: CustomStringConvertible,
        RightField.Model == Right,
        RightField: FieldProtocol,
        RightField.Value: CustomStringConvertible
{
    .init(lhs, .contains(inverse: true, .prefix), rhs)
}

public struct ModelFieldFilter<Left, Right>
    where Left: FluentKit.Model, Right: FluentKit.Model
{
    init<LeftField, RightField>(
        _ lhs: KeyPath<Left, LeftField>,
        _ method: DatabaseQuery.Filter.Method,
        _ rhs: KeyPath<Right, RightField>
    )
        where LeftField: FieldProtocol, RightField: FieldProtocol
    {
        self.lhsPath = Left.init()[keyPath: lhs].path
        self.method = method
        self.rhsPath = Right.init()[keyPath: rhs].path
    }

    let lhsPath: [FieldKey]
    let method: DatabaseQuery.Filter.Method
    let rhsPath: [FieldKey]
}
