extension QueryBuilder {
    // MARK: Filter

    @discardableResult
    public func filter<Field>(
        _ field: KeyPath<Model, Field>,
        _ method: DatabaseQuery.Filter.Method,
        _ value: Field.Value
    ) -> Self
        where Field: QueryableProperty, Field.Model == Model
    {
        self.filter(Model.path(for: field), method, value)
    }

    @discardableResult
    public func filter<Left, Right>(
        _ lhsField: KeyPath<Model, Left>,
        _ method: DatabaseQuery.Filter.Method,
        _ rhsField: KeyPath<Model, Right>
    ) -> Self
        where Left: QueryableProperty,
            Left.Model == Model,
            Right: QueryableProperty,
            Right.Model == Model
    {
        self.filter(Model.path(for: lhsField), method, Model.path(for: rhsField))
    }

    @discardableResult
    public func filter<Value>(
        _ fieldName: FieldKey,
        _ method: DatabaseQuery.Filter.Method,
        _ value: Value
    ) -> Self
        where Value: Codable
    {
        self.filter([fieldName], method, value)
    }

    @discardableResult
    public func filter<Value>(
        _ fieldPath: [FieldKey],
        _ method: DatabaseQuery.Filter.Method,
        _ value: Value
    ) -> Self
        where Value: Codable
    {
        self.filter(
            .path(fieldPath, schema: Model.schema),
            method,
            .bind(value)
        )
    }

    @discardableResult
    public func filter(
        _ leftName: FieldKey,
        _ method: DatabaseQuery.Filter.Method,
        _ rightName: FieldKey
    ) -> Self {
        self.filter([leftName], method, [rightName])
    }

    @discardableResult
    public func filter(
        _ leftPath: [FieldKey],
        _ method: DatabaseQuery.Filter.Method,
        _ rightPath: [FieldKey]
    ) -> Self {
        self.filter(
            .path(leftPath, schema: Model.schema),
            method,
            .path(rightPath, schema: Model.schema)
        )
    }

    @discardableResult
    public func filter(
        _ field: DatabaseQuery.Field,
        _ method: DatabaseQuery.Filter.Method,
        _ value: DatabaseQuery.Value
    ) -> Self {
        self.filter(.value(field, method, value))
    }

    @discardableResult
    public func filter(
        _ lhsField: DatabaseQuery.Field,
        _ method: DatabaseQuery.Filter.Method,
        _ rhsField: DatabaseQuery.Field
    ) -> Self {
        self.filter(.field(lhsField, method, rhsField))
    }

    @discardableResult
    public func filter(_ filter: DatabaseQuery.Filter) -> Self {
        self.query.filters.append(filter)
        return self
    }
}
