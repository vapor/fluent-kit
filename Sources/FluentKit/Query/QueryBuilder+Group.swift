extension QueryBuilder {
    public func group(
        _ relation: DatabaseQuery.Filter.Relation = .and,
        _ closure: (QueryBuilder<Model>) throws -> ()
    ) rethrows -> Self {
        let group = QueryBuilder(database: self.database)
        try closure(group)
        self.query.filters.append(.group(group.query.filters, relation))
        return self
    }
}
