extension QueryBuilder {
    // MARK: Sort

    public func sort<Field>(
        _ field: KeyPath<Model, Field>,
        _ direction: DatabaseQuery.Sort.Direction = .ascending
    ) -> Self
        where
            Field: QueryField,
            Field.Model == Model
    {
        self.sort(.key(for: field), direction)
    }

    public func sort(
        _ field: FieldKey,
        _ direction: DatabaseQuery.Sort.Direction = .ascending
    ) -> Self {
        self.sort(.field(field, schema: Model.schema), direction)
    }

    public func sort<Joined, Field>(
        _ joined: Joined.Type,
        _ field: KeyPath<Joined, Field>,
        _ direction: DatabaseQuery.Sort.Direction = .ascending,
        alias: String? = nil
    ) -> Self
        where
            Field: QueryField,
            Field.Model == Joined,
            Joined: Schema
    {
        self.sort(Joined.self, .key(for: field), direction, alias: alias)
    }

    public func sort<Joined>(
        _ model: Joined.Type,
        _ field: FieldKey,
        _ direction: DatabaseQuery.Sort.Direction = .ascending,
        alias: String? = nil
    ) -> Self
        where Joined: Schema
    {
        self.sort(.field(field, schema: Joined.schema), direction)
    }

    public func sort(
        _ field: DatabaseQuery.Field,
        _ direction: DatabaseQuery.Sort.Direction = .ascending
    ) -> Self {
        self.query.sorts.append(.sort(field, direction))
        return self
    }
}
