extension QueryBuilder {
    // MARK: Set
    
    @discardableResult
    public func set(_ data: [FieldKey: DatabaseQuery.Value]) -> Self {
        self.set([data])
    }

    @discardableResult
    public func set(_ data: [[FieldKey: DatabaseQuery.Value]]) -> Self {
        self.query.input = data.map {
            .dictionary($0)
        }
        return self
    }

    // MARK: Set

    @discardableResult
    public func set<Field>(
        _ field: KeyPath<Model, Field>,
        to value: Field.Value
    ) -> Self
        where Field: QueryableProperty, Field.Model == Model.IDValue
    {
        if self.query.input.isEmpty {
            self.query.input = [.dictionary([:])]
        }

        switch self.query.input[0] {
        case .dictionary(var existing):
            let path = Model.path(for: field)
            assert(path.count == 1, "Set on nested properties is not yet supported.")
            existing[path[0]] = Field.queryValue(value)
            self.query.input[0] = .dictionary(existing)
        default:
            fatalError()
        }

        return self
    }

    @discardableResult
    public func set<Field>(
        _ field: KeyPath<Model, Field>,
        to value: Field.Value
    ) -> Self
        where Field: QueryableProperty, Field.Model == Model
    {
        if self.query.input.isEmpty {
            self.query.input = [.dictionary([:])]
        }

        switch self.query.input[0] {
        case .dictionary(var existing):
            let path = Model.path(for: field)
            assert(path.count == 1, "Set on nested properties is not yet supported.")
            existing[path[0]] = Field.queryValue(value)
            self.query.input[0] = .dictionary(existing)
        default:
            fatalError()
        }

        return self
    }
}
