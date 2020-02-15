extension QueryBuilder {
    // MARK: Aggregate

    public func count() -> EventLoopFuture<Int> {
        return self.aggregate(.count, Model.key(for: \Model._$id), as: Int.self)
    }

    public func sum<Field>(_ key: KeyPath<Model, Field>) -> EventLoopFuture<Field.Value?>
        where Field: FieldRepresentable,
            Field.Model == Model
    {
        return self.aggregate(.sum, key)
    }

    public func sum<Field>(_ key: KeyPath<Model, Field>) -> EventLoopFuture<Field.Value>
        where Field: FieldRepresentable,
            Field.Value: OptionalType,
            Field.Model == Model
    {
        return self.aggregate(.sum, key)
    }

    public func average<Field>(_ key: KeyPath<Model, Field>) -> EventLoopFuture<Field.Value?>
        where Field: FieldRepresentable,
            Field.Model == Model
    {
        return self.aggregate(.average, key)
    }

    public func average<Field>(_ key: KeyPath<Model, Field>) -> EventLoopFuture<Field.Value>
        where Field: FieldRepresentable,
            Field.Value: OptionalType,
            Field.Model == Model
    {
        return self.aggregate(.average, key)
    }

    public func min<Field>(_ key: KeyPath<Model, Field>) -> EventLoopFuture<Field.Value?>
        where Field: FieldRepresentable,
            Field.Model == Model
    {
        return self.aggregate(.minimum, key)
    }

    public func min<Field>(_ key: KeyPath<Model, Field>) -> EventLoopFuture<Field.Value>
        where Field: FieldRepresentable,
            Field.Value: OptionalType,
            Field.Model == Model
    {
        return self.aggregate(.minimum, key)
    }

    public func max<Field>(_ key: KeyPath<Model, Field>) -> EventLoopFuture<Field.Value?>
        where Field: FieldRepresentable,
            Field.Model == Model
    {
        return self.aggregate(.maximum, key)
    }

    public func max<Field>(_ key: KeyPath<Model, Field>) -> EventLoopFuture<Field.Value>
        where Field: FieldRepresentable,
            Field.Value: OptionalType,
            Field.Model == Model
    {
        return self.aggregate(.maximum, key)
    }

    public func aggregate<Field, Result>(
        _ method: DatabaseQuery.Field.Aggregate.Method,
        _ field: KeyPath<Model, Field>,
        as type: Result.Type = Result.self
    ) -> EventLoopFuture<Result>
        where Field: FieldRepresentable, Result: Codable
    {
        return self.aggregate(method, Model()[keyPath: field].field.key, as: Result.self)
    }

    public func aggregate<Result>(
        _ method: DatabaseQuery.Field.Aggregate.Method,
        _ fieldName: String,
        as type: Result.Type = Result.self
    ) -> EventLoopFuture<Result>
        where Result: Codable
    {
        let copy = self.copy()
        copy.query.fields = [.aggregate(.fields(
            method: method,
            fields: [.field(
                path: [fieldName],
                schema: Model.schema,
                alias: nil)
            ]
        ))]

        return copy.first().flatMapThrowing { res in
            guard let res = res else {
                throw FluentError.noResults
            }
            return try res._$id.cachedOutput!.decode("fluentAggregate", as: Result.self)
        }
    }
}
