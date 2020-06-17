// MARK: - Filter Groups

extension QueryBuilder {
    @discardableResult
    public func group(
        _ relation: DatabaseQuery.Filter.Relation = .and,
        _ closure: (QueryBuilder<Model>) throws -> ()
    ) rethrows -> Self {
        let group = QueryBuilder(database: self.database)
        try closure(group)
        if !group.query.filters.isEmpty {
            self.query.filters.append(.group(group.query.filters, relation))
        }
        return self
    }
}


// MARK: - Group By

extension QueryBuilder {
    @discardableResult
    public func group<Field>(by field: KeyPath<Model, Field>) -> Self
        where Field: QueryableProperty, Field.Model == Model
    {
        self.group(by: Model.self, field)
    }

    @discardableResult
    public func group<Schema, Field>(by schema: Schema.Type = Schema.self, _ field: KeyPath<Schema, Field>) -> Self
        where Field: QueryableProperty, Schema: FluentKit.Model, Field.Model == Schema
    {
        self.group(by: schema, Schema.path(for: field))
    }


    @discardableResult
    public func group(by fields: FieldKey...) -> Self {
        self.group(by: Model.self, fields)
    }

    @discardableResult
    public func group(by fields: [FieldKey]) -> Self {
        self.group(by: .path(fields, schema: Model.schema))
    }

    @discardableResult
    public func group<Schema>(by schema: Schema.Type, _ fields: FieldKey...) -> Self
        where Schema: FluentKit.Model
    {
        self.group(by: schema, fields)
    }

    @discardableResult
    public func group<Schema>(by schema: Schema.Type, _ fields: [FieldKey]) -> Self
        where Schema: FluentKit.Model
    {
        self.group(by: .path(fields, schema: Schema.schema))
    }


    @discardableResult
    public func group(by fields: DatabaseQuery.Field...) -> Self {
        self.group(by: fields)
    }

    @discardableResult
    public func group(by fields: [DatabaseQuery.Field]) -> Self {
        self.query.groups.append(contentsOf: fields)
        return self
    }
}
