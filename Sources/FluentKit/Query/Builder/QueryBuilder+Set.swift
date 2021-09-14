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
        where
            Field: QueryableProperty,
            Field.Model == Model
    {
        return prepareSelf(by: Model.path(for: field), queryValue: Field.queryValue(value))
    }
    
    // MARK: Set

    @discardableResult
    public func set<Field>(
        _ field: KeyPath<Model, Field>,
        to value: Field.Value
    ) -> Self
        where
            Field: QueryableProperty,
            Field.Model == GroupPropertyPath<Model, QueryableProperty>.Model
    {
        return prepareSelf(by: Model.path(for: field), queryValue: Field.queryValue(value))
    }
    
    private func prepareSelf(by path: [FieldKey], queryValue: DatabaseQuery.Value) -> Self {
        if self.query.input.isEmpty {
            self.query.input = [.dictionary([:])]
        }

        switch self.query.input[0] {
        case .dictionary(var existing):
            assert(path.count == 1, "Set on nested properties is not yet supported.")
            existing[path[0]] = queryValue
            self.query.input[0] = .dictionary(existing)
        default:
            fatalError()
        }

        return self
    }
}
