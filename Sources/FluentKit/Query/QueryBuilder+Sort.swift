extension QueryBuilder {
    // MARK: Sort

    public func sort<Field>(
        _ field: KeyPath<Model, Field>,
        _ direction: DatabaseQuery.Sort.Direction = .ascending
    ) -> Self
        where Field: FieldProtocol,
            Field.Model == Model
    {
        self.sort(Model.self, Model.path(for: field), direction, alias: nil)
    }

    public func sort(
        _ field: FieldKey,
        _ direction: DatabaseQuery.Sort.Direction = .ascending
    ) -> Self {
        self.sort(Model.self, [field], direction, alias: nil)
    }

    public func sort(
        _ field: [FieldKey],
        _ direction: DatabaseQuery.Sort.Direction = .ascending
    ) -> Self {
        self.sort(Model.self, field, direction, alias: nil)
    }

    public func sort<Joined, Field>(
        _ joined: Joined.Type,
        _ field: KeyPath<Joined, Field>,
        _ direction: DatabaseQuery.Sort.Direction = .ascending,
        alias: String? = nil
    ) -> Self
        where Field: FieldProtocol,
            Field.Model == Joined,
            Joined: FluentKit.Model
    {
        self.sort(Joined.self, Joined.path(for: field), direction, alias: alias)
    }

    public func sort<Joined>(
        _ model: Joined.Type,
        _ field: FieldKey,
        _ direction: DatabaseQuery.Sort.Direction = .ascending,
        alias: String? = nil
    ) -> Self
        where Joined: FluentKit.Model
    {
        self.sort(Joined.self, [field], direction, alias: alias)
    }

    public func sort<Joined>(
        _ model: Joined.Type,
        _ fieldPath: [FieldKey],
        _ direction: DatabaseQuery.Sort.Direction = .ascending,
        alias: String? = nil
    ) -> Self
        where Joined: FluentKit.Model
    {
        self.query.sorts.append(.sort(field: .field(
            path: fieldPath,
            schema: alias ?? Joined.schema,
            alias: nil
        ), direction: direction))
        return self
    }
}
