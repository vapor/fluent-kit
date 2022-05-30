extension QueryBuilder {
    // MARK: Filter
    
    @discardableResult
    internal func filter(id: Model.IDValue) -> Self {
        if let fields = id as? Fields {
            assert(!(Model.init().anyID is AnyQueryableProperty), "Model's IDValue should not conform to Fields if it can be directly queried.")
            return self.group(.and) { query in
                _ = fields.properties.map { $0 as! AnyQueryAddressableProperty }.reduce(query) { query, prop in
                    prop.anyQueryableProperty.queryableValue().map {
                        query.filter(.extendedPath(prop.queryablePath, schema: Model.schema, space: Model.space), .equal, $0)
                    } ?? query
                }
            }
        } else {
            return self.filter(\Model._$id == id)
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
            space: Model.space
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
            space: Joined.space
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
            .extendedPath(fieldPath, schema: Model.schema, space: Model.space),
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
            .extendedPath(leftPath, schema: Model.schema, space: Model.space),
            method,
            .extendedPath(rightPath, schema: Model.schema, space: Model.space)
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
