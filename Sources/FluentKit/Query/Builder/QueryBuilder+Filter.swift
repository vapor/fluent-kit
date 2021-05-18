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
        self.filter(.path(
            Model.path(for: field),
            schema: Model.schemaOrAlias
        ), method, Field.queryValue(value))
    }

    @discardableResult
    public func filter<Joined, Field>(
        _ joined: Joined.Type,
        _ field: KeyPath<Joined, Field>,
        _ method: DatabaseQuery.Filter.Method,
        _ value: Field.Value
    ) -> Self
        where Joined: Schema, Field: QueryableProperty, Field.Model == Joined
    {
        self.filter(.path(
            Joined.path(for: field),
            schema: Joined.schemaOrAlias
        ), method, Field.queryValue(value))
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
    public func filter<LeftJoined, LeftField, RightJoined, RightField>(
        _ leftJoined: LeftJoined.Type,
        _ leftField: KeyPath<LeftJoined, LeftField>,
        _ method: DatabaseQuery.Filter.Method,
        _ rightJoined: RightJoined.Type,
        _ rightField: KeyPath<RightJoined, RightField>
    ) -> Self
    where LeftJoined: Schema,
          RightJoined: Schema,
          LeftField: QueryableProperty,
          RightField: QueryableProperty,
          LeftField.Model == LeftJoined,
          RightField.Model == RightJoined
    {
        self.filter(
            .path(LeftJoined.path(for: leftField), schema: LeftJoined.schemaOrAlias),
            method,
            .path(RightJoined.path(for: rightField), schema: RightJoined.schemaOrAlias)
        )
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
