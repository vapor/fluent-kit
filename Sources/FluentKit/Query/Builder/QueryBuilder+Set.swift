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
            Field: FieldProtocol,
            Field.Model == Model
    {
        if self.query.input.isEmpty {
            self.query.input = [.dictionary([:])]
        }

        switch self.query.input[0] {
        case .dictionary(var existing):
            existing[Model.path(for: field)[0]] = .bind(value)
            self.query.input[0] = .dictionary(existing)
        default:
            fatalError()
        }

        return self
    }
}
