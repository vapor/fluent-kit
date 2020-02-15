extension QueryBuilder {
    // MARK: Set
    
    @discardableResult
    public func set(_ data: [String: DatabaseQuery.Value]) -> Self {
        self.set([data])
    }

    @discardableResult
    public func set(_ data: [[String: DatabaseQuery.Value]]) -> Self {
        assert(self.query.fields.isEmpty, "Conflicting query fields already exist.")
        // ensure there is at least one
        guard let keys = data.first?.keys else {
            return self
        }
        // use first copy of keys to ensure correct ordering
        self.query.fields = keys.map { .field(path: [$0], schema: nil, alias: nil) }
        for item in data {
            let input = keys.map { item[$0]! }
            self.query.input.append(input)
        }
        return self
    }

    // MARK: Set

    @discardableResult
    public func set<Field>(
        _ field: KeyPath<Model, Field>,
        to value: Field.Value
    ) -> Self
        where Field: FieldRepresentable,
            Field.Model == Model
    {
        self.query.fields.append(.field(path: [Model.key(for: field)], schema: nil, alias: nil))
        switch query.input.count {
        case 0: query.input = [[.bind(value)]]
        default: query.input[0].append(.bind(value))
        }
        return self
    }
}
