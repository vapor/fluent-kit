extension QueryBuilder {
    // MARK: Filter
    
    @discardableResult
    internal func filter(id: Model.IDValue) -> Self {
        if let fields = id as? Fields {
            return self.group(.and) { fields.input(to: QueryFilterInput(builder: $0)) }
        } else {
            return self.filter(\Model._$id == id)
        }
    }
    
    @discardableResult
    internal func filter(ids: [Model.IDValue]) -> Self {
        guard let firstId = ids.first else { return self.limit(0) }
        if firstId is Fields {
            return self.group(.or) { q in ids.forEach { id in q.group(.and) { (id as! Fields).input(to: QueryFilterInput(builder: $0)) } } }
        } else {
            return self.filter(\Model._$id ~~ ids)
        }
    }

    @discardableResult
    public func filter<Field>(
        _ field: KeyPath<Model, Field>,
        _ method: DatabaseQuery.Filter.Method,
        _ value: Field.Value
    ) -> Self
        where Field: QueryableProperty, Field.Model == Model
    {
        self.filter(.extendedPath(
            Model.path(for: field),
            schema: Model.schemaOrAlias,
            space: Model.spaceIfNotAliased
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
        self.filter(.extendedPath(
            Joined.path(for: field),
            schema: Joined.schemaOrAlias,
            space: Joined.spaceIfNotAliased
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
            .extendedPath(fieldPath, schema: Model.schemaOrAlias, space: Model.spaceIfNotAliased),
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
            .extendedPath(leftPath, schema: Model.schemaOrAlias, space: Model.spaceIfNotAliased),
            method,
            .extendedPath(rightPath, schema: Model.schemaOrAlias, space: Model.spaceIfNotAliased)
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
