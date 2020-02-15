extension QueryBuilder {
    @discardableResult
    public func filter(_ filter: ModelFieldFilter<Model, Model>) -> Self {
        self.filter(
            .field(path: filter.lhsPath, schema: Model.schema, alias: nil),
            filter.method,
            .field(path: filter.rhsPath, schema: Model.schema, alias: nil)
        )
    }

    @discardableResult
    public func filter<Left, Right>(_ filter: ModelFieldFilter<Left, Right>) -> Self
        where Left: FluentKit.Model, Right: FluentKit.Model
    {
        self.filter(
            .field(path: filter.lhsPath, schema: Left.schema, alias: nil),
            filter.method,
            .field(path: filter.rhsPath, schema: Right.schema, alias: nil)
        )
    }

    @discardableResult
    public func filter<Alias>(_ alias: Alias.Type, _ filter: ModelFieldFilter<Alias.Model, Alias.Model>) -> Self
        where Alias: ModelAlias
    {
        self.filter(
            .field(path: filter.lhsPath, schema: Alias.alias, alias: nil),
            filter.method,
            .field(path: filter.rhsPath, schema: Alias.alias, alias: nil)
        )
    }

    @discardableResult
    public func filter<Joined>(_ alias: Joined.Type, _ filter: ModelFieldFilter<Joined, Joined>) -> Self
        where Joined: FluentKit.Model
    {
        self.filter(
            .field(path: filter.lhsPath, schema: Joined.schema, alias: nil),
            filter.method,
            .field(path: filter.rhsPath, schema: Joined.schema, alias: nil)
        )
    }
}

public func == <Left, Right, LeftField, RightField>(
    lhs: KeyPath<Left, LeftField>,
    rhs: KeyPath<Right, RightField>
) -> ModelFieldFilter<Left, Right>
    where LeftField.Model == Left,
        LeftField: FieldRepresentable,
        RightField.Model == Right,
        RightField: FieldRepresentable
{
    .init(lhs, .equal, rhs)
}

public func != <Left, Right, LeftField, RightField>(
    lhs: KeyPath<Left, LeftField>,
    rhs: KeyPath<Right, RightField>
) -> ModelFieldFilter<Left, Right>
    where LeftField.Model == Left,
        LeftField: FieldRepresentable,
        RightField.Model == Right,
        RightField: FieldRepresentable
{
    .init(lhs, .notEqual, rhs)
}

public func >= <Left, Right, LeftField, RightField>(
    lhs: KeyPath<Left, LeftField>,
    rhs: KeyPath<Right, RightField>
) -> ModelFieldFilter<Left, Right>
    where LeftField.Model == Left,
        LeftField: FieldRepresentable,
        RightField.Model == Right,
        RightField: FieldRepresentable
{
    .init(lhs, .greaterThanOrEqual, rhs)
}

public func > <Left, Right, LeftField, RightField>(
    lhs: KeyPath<Left, LeftField>,
    rhs: KeyPath<Right, RightField>
) -> ModelFieldFilter<Left, Right>
    where LeftField.Model == Left,
        LeftField: FieldRepresentable,
        RightField.Model == Right,
        RightField: FieldRepresentable
{
    .init(lhs, .greaterThan, rhs)
}

public func < <Left, Right, LeftField, RightField>(
    lhs: KeyPath<Left, LeftField>,
    rhs: KeyPath<Right, RightField>
) -> ModelFieldFilter<Left, Right>
    where LeftField.Model == Left,
        LeftField: FieldRepresentable,
        RightField.Model == Right,
        RightField: FieldRepresentable
{
    .init(lhs, .lessThan, rhs)
}

public func <= <Left, Right, LeftField, RightField>(
    lhs: KeyPath<Left, LeftField>,
    rhs: KeyPath<Right, RightField>
) -> ModelFieldFilter<Left, Right>
    where LeftField.Model == Left,
        LeftField: FieldRepresentable,
        RightField.Model == Right,
        RightField: FieldRepresentable
{
    .init(lhs, .lessThanOrEqual, rhs)
}

public func ~= <Left, Right, LeftField, RightField>(
    lhs: KeyPath<Left, LeftField>,
    rhs: KeyPath<Right, RightField>
) -> ModelFieldFilter<Left, Right>
    where LeftField.Model == Left,
        LeftField: FieldRepresentable,
        LeftField.Value: CustomStringConvertible,
        RightField.Model == Right,
        RightField: FieldRepresentable,
        RightField.Value: CustomStringConvertible
{
    .init(lhs, .contains(inverse: false, .suffix), rhs)
}

public func ~~ <Left, Right, LeftField, RightField>(
    lhs: KeyPath<Left, LeftField>,
    rhs: KeyPath<Right, RightField>
) -> ModelFieldFilter<Left, Right>
    where LeftField.Model == Left,
        LeftField: FieldRepresentable,
        LeftField.Value: CustomStringConvertible,
        RightField.Model == Right,
        RightField: FieldRepresentable,
        RightField.Value: CustomStringConvertible
{
    .init(lhs, .contains(inverse: false, .anywhere), rhs)
}

public func =~ <Left, Right, LeftField, RightField>(
    lhs: KeyPath<Left, LeftField>,
    rhs: KeyPath<Right, RightField>
) -> ModelFieldFilter<Left, Right>
    where LeftField.Model == Left,
        LeftField: FieldRepresentable,
        LeftField.Value: CustomStringConvertible,
        RightField.Model == Right,
        RightField: FieldRepresentable,
        RightField.Value: CustomStringConvertible
{
    .init(lhs, .contains(inverse: false, .prefix), rhs)
}

public func !~= <Left, Right, LeftField, RightField>(
    lhs: KeyPath<Left, LeftField>,
    rhs: KeyPath<Right, RightField>
) -> ModelFieldFilter<Left, Right>
    where LeftField.Model == Left,
        LeftField: FieldRepresentable,
        LeftField.Value: CustomStringConvertible,
        RightField.Model == Right,
        RightField: FieldRepresentable,
        RightField.Value: CustomStringConvertible
{
    .init(lhs, .contains(inverse: true, .suffix), rhs)
}

public func !~ <Left, Right, LeftField, RightField>(
    lhs: KeyPath<Left, LeftField>,
    rhs: KeyPath<Right, RightField>
) -> ModelFieldFilter<Left, Right>
    where LeftField.Model == Left,
        LeftField: FieldRepresentable,
        LeftField.Value: CustomStringConvertible,
        RightField.Model == Right,
        RightField: FieldRepresentable,
        RightField.Value: CustomStringConvertible
{
    .init(lhs, .contains(inverse: true, .anywhere), rhs)
}

public func !=~ <Left, Right, LeftField, RightField>(
    lhs: KeyPath<Left, LeftField>,
    rhs: KeyPath<Right, RightField>
) -> ModelFieldFilter<Left, Right>
    where LeftField.Model == Left,
        LeftField: FieldRepresentable,
        LeftField.Value: CustomStringConvertible,
        RightField.Model == Right,
        RightField: FieldRepresentable,
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
        where LeftField: FieldRepresentable, RightField: FieldRepresentable
    {
        self.lhsPath = [Left.init()[keyPath: lhs].field.key]
        self.method = method
        self.rhsPath = [Right.init()[keyPath: rhs].field.key]
    }

    let lhsPath: [String]
    let method: DatabaseQuery.Filter.Method
    let rhsPath: [String]
}
