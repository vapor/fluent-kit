public protocol SoftDeletable: Model, _AnySoftDeletable {
    var deletedAt: Field<Date?> { get }
}

public protocol _AnySoftDeletable {
    func _clearDeletedAt(from input: inout [String: DatabaseQuery.Value])
    func _excludeSoftDeleted(from query: inout DatabaseQuery)
}

extension SoftDeletable {
    public func _clearDeletedAt(from input: inout [String: DatabaseQuery.Value]) {
        input[self.deletedAt.name] = .bind(Date())
    }
    
    public func _excludeSoftDeleted(from query: inout DatabaseQuery) {
        let deletedAtField = DatabaseQuery.Field.field(
            path: [self.deletedAt.name],
            entity: Self.entity,
            alias: nil
        )
        let isNull = DatabaseQuery.Filter.basic(deletedAtField, .equal, .null)
        let isFuture = DatabaseQuery.Filter.basic(deletedAtField, .greaterThan, .bind(Date()))
        query.filters.append(.group([isNull, isFuture], .or))
    }
}

extension QueryBuilder {
    public func withSoftDeleted() -> Self {
        self.includeSoftDeleted = true
        return self
    }
}
