public protocol SoftDeletable: Model, _AnySoftDeletable {
    var deletedAt: Date? { get set }
}

public protocol _AnySoftDeletable {
    var _deletedAtField: Field<Date?> { get }
    func _excludeSoftDeleted(_ query: inout DatabaseQuery)
}

extension SoftDeletable {
    public var _deletedAtField: Field<Date?> {
        guard let deletedAt = Mirror(reflecting: self).descendant("_deletedAt") else {
            fatalError("deletedAt must be declared using @Field")
        }
        return deletedAt as! Field<Date?>
    }

    public func _excludeSoftDeleted(_ query: inout DatabaseQuery) {
        let deletedAtField = DatabaseQuery.Field.field(
            path: [Self.key(for: \._deletedAtField)],
            entity: Self.entity,
            alias: nil
        )
        let isNull = DatabaseQuery.Filter.basic(deletedAtField, .equal, .null)
        let isFuture = DatabaseQuery.Filter.basic(deletedAtField, .greaterThan, .bind(Date()))
        query.filters.append(.group([isNull, isFuture], .or))
    }
}
