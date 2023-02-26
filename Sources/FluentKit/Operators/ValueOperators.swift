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
            .extendedPath(filter.path, schema: Joined.schemaOrAlias, space: Joined.spaceIfNotAliased),
            filter.method,
            filter.value
        )
    }
    
    @discardableResult
    public func filter(_ filter: ModelCompositeIDFilter<Model>) -> Self
        where Model.IDValue: Fields
    {
        self.filter(Model.self, filter)
    }
    
    @discardableResult
    public func filter<Joined>(
        _ schema: Joined.Type,
        _ filter: ModelCompositeIDFilter<Joined>
    ) -> Self
        where Joined: Schema, Joined.IDValue: Fields
    {
        let relation: DatabaseQuery.Filter.Relation
        let inverted: Bool
        switch filter.method {
        case .equality(false): (relation, inverted) = (.and, false)
        case .equality(true):  (relation, inverted) = (.or, true)
        default: fatalError("unreachable")
        }
        
        return self.group(relation) { filter.value.input(to: QueryFilterInput(builder: $0, inverted: inverted)) }
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

// MARK: CompositeID.Value

public func == <Model, IDValue>(lhs: KeyPath<Model, CompositeIDProperty<Model, IDValue>>, rhs: Model.IDValue) -> ModelCompositeIDFilter<Model> {
    .init(.equal, rhs)
}

public func != <Model, IDValue>(lhs: KeyPath<Model, CompositeIDProperty<Model, IDValue>>, rhs: Model.IDValue) -> ModelCompositeIDFilter<Model> {
    .init(.notEqual, rhs)
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
    public init<Field>(
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

public struct ModelCompositeIDFilter<Model> where Model: FluentKit.Model, Model.IDValue: Fields {
    public init(
        _ method: DatabaseQuery.Filter.Method,
        _ rhs: Model.IDValue
    ) {
        guard case .equality(_) = method else { preconditionFailure("Composite IDs may only be compared for equality or inequality.") }
        
        self.method = method
        self.value = rhs
    }
    
    let method: DatabaseQuery.Filter.Method
    let value: Model.IDValue
}
