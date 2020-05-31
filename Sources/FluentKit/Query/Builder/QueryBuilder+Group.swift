extension QueryBuilder {
    @discardableResult
    public func group(
        _ relation: DatabaseQuery.Filter.Relation = .and,
        _ closure: (QueryBuilder<Model>) throws -> ()
    ) rethrows -> Self {
        let a = QueryBuilder<Model>(database: self.database, namespace: [])
        guard let group = a else { fatalError("Table aliasing must be enabled for namespaced tables") }
        try closure(group)
        if !group.query.filters.isEmpty {
            self.query.filters.append(.group(group.query.filters, relation))
        }
        return self
    }
}
