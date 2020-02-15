extension QueryBuilder {
    // MARK: Filter

    @discardableResult
    public func filter<Field>(
        _ field: KeyPath<Model, Field>,
        _ method: DatabaseQuery.Filter.Method,
        _ value: Field.Value
    ) -> Self
        where Field: FieldRepresentable, Field.Model == Model
    {
        self.filter(Model.key(for: field), method, value)
    }

    @discardableResult
    public func filter<Left, Right>(
        _ lhsField: KeyPath<Model, Left>,
        _ method: DatabaseQuery.Filter.Method,
        _ rhsField: KeyPath<Model, Right>
    ) -> Self
        where Left: FieldRepresentable,
            Left.Model == Model,
            Right: FieldRepresentable,
            Right.Model == Model
    {
        self.filter(Model.key(for: lhsField), method, Model.key(for: rhsField))
    }

    @discardableResult
    public func filter<Value>(
        _ fieldName: String,
        _ method: DatabaseQuery.Filter.Method,
        _ value: Value
    ) -> Self
        where Value: Codable
    {
        self.filter(.field(
            path: [fieldName],
            schema: Model.schema,
            alias: nil
        ), method, .bind(value))
    }

    @discardableResult
    public func filter(
        _ lhsFieldName: String,
        _ method: DatabaseQuery.Filter.Method,
        _ rhsFieldName: String
    ) -> Self {
        self.filter(
            .field(path: [lhsFieldName], schema: Model.schema, alias: nil),
            method,
            .field(path: [rhsFieldName], schema: Model.schema, alias: nil)
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
