extension QueryBuilder {
    // MARK: Sort

    public func sort<Field>(
        _ field: KeyPath<Model, Field>,
        _ direction: DatabaseQuery.Sort.Direction = .ascending
    ) -> Self
        where Field: FieldRepresentable,
            Field.Model == Model
    {
        self.sort(Model.self, Model.key(for: field), direction, alias: nil)
    }


    public func sort<Joined, Field>(
        _ field: KeyPath<Joined, Field>,
        _ direction: DatabaseQuery.Sort.Direction = .ascending,
        alias: String? = nil
    ) -> Self
        where Field: FieldRepresentable,
            Field.Model == Joined
    {
        self.sort(Joined.self, Joined.key(for: field), direction, alias: alias)
    }

    public func sort(
        _ field: String,
        _ direction: DatabaseQuery.Sort.Direction = .ascending
    ) -> Self {
        self.sort(Model.self, field, direction, alias: nil)
    }

    public func sort<Joined>(
        _ model: Joined.Type,
        _ field: String,
        _ direction: DatabaseQuery.Sort.Direction = .ascending,
        alias: String? = nil
    ) -> Self
        where Joined: FluentKit.Model
    {
        self.query.sorts.append(.sort(field: .field(
            path: [field],
            schema: alias ?? Joined.schema,
            alias: nil
        ), direction: direction))
        return self
    }
}
