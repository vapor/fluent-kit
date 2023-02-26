import NIOCore

extension QueryBuilder {
    // MARK: Aggregate

    public func count() -> EventLoopFuture<Int> {
        if Model().anyID is AnyQueryableProperty {
            return self.count(\._$id)
        } else if let fieldsIDType = Model.IDValue.self as? Fields.Type {
            return self.aggregate(.count, fieldsIDType.keys.first!)
        } else {
            fatalError("Model '\(Model.self)' has neither @ID nor @CompositeID, this is not valid.")
        }
    }

    public func count<Field>(_ key: KeyPath<Model, Field>) -> EventLoopFuture<Int>
        where Field: QueryableProperty, Field.Model == Model
    {
        self.aggregate(.count, key, as: Int.self)
    }

    public func count<Field>(_ key: KeyPath<Model, Field>) -> EventLoopFuture<Int>
        where Field: QueryableProperty, Field.Model == Model.IDValue
    {
        self.aggregate(.count, key, as: Int.self)
    }

    public func sum<Field>(_ key: KeyPath<Model, Field>) -> EventLoopFuture<Field.Value?>
        where Field: QueryableProperty, Field.Model == Model
    {
        self.aggregate(.sum, key)
    }

    public func sum<Field>(_ key: KeyPath<Model, Field>) -> EventLoopFuture<Field.Value?>
        where Field: QueryableProperty, Field.Model == Model.IDValue
    {
        self.aggregate(.sum, key)
    }

    public func sum<Field>(_ key: KeyPath<Model, Field>) -> EventLoopFuture<Field.Value>
        where Field: QueryableProperty, Field.Value: OptionalType, Field.Model == Model
    {
        self.aggregate(.sum, key)
    }

    public func sum<Field>(_ key: KeyPath<Model, Field>) -> EventLoopFuture<Field.Value>
        where Field: QueryableProperty, Field.Value: OptionalType, Field.Model == Model.IDValue
    {
        self.aggregate(.sum, key)
    }

    public func average<Field>(_ key: KeyPath<Model, Field>) -> EventLoopFuture<Field.Value?>
        where Field: QueryableProperty, Field.Model == Model
    {
        self.aggregate(.average, key)
    }

    public func average<Field>(_ key: KeyPath<Model, Field>) -> EventLoopFuture<Field.Value?>
        where Field: QueryableProperty, Field.Model == Model.IDValue
    {
        self.aggregate(.average, key)
    }

    public func average<Field>(_ key: KeyPath<Model, Field>) -> EventLoopFuture<Field.Value>
        where Field: QueryableProperty, Field.Value: OptionalType, Field.Model == Model
    {
        self.aggregate(.average, key)
    }

    public func average<Field>(_ key: KeyPath<Model, Field>) -> EventLoopFuture<Field.Value>
        where Field: QueryableProperty, Field.Value: OptionalType, Field.Model == Model.IDValue
    {
        self.aggregate(.average, key)
    }

    public func min<Field>(_ key: KeyPath<Model, Field>) -> EventLoopFuture<Field.Value?>
        where Field: QueryableProperty, Field.Model == Model
    {
        self.aggregate(.minimum, key)
    }

    public func min<Field>(_ key: KeyPath<Model, Field>) -> EventLoopFuture<Field.Value?>
        where Field: QueryableProperty, Field.Model == Model.IDValue
    {
        self.aggregate(.minimum, key)
    }

    public func min<Field>(_ key: KeyPath<Model, Field>) -> EventLoopFuture<Field.Value>
        where Field: QueryableProperty, Field.Value: OptionalType, Field.Model == Model
    {
        self.aggregate(.minimum, key)
    }

    public func min<Field>(_ key: KeyPath<Model, Field>) -> EventLoopFuture<Field.Value>
        where Field: QueryableProperty, Field.Value: OptionalType, Field.Model == Model.IDValue
    {
        self.aggregate(.minimum, key)
    }

    public func max<Field>(_ key: KeyPath<Model, Field>) -> EventLoopFuture<Field.Value?>
        where Field: QueryableProperty, Field.Model == Model
    {
        self.aggregate(.maximum, key)
    }

    public func max<Field>(_ key: KeyPath<Model, Field>) -> EventLoopFuture<Field.Value?>
        where Field: QueryableProperty, Field.Model == Model.IDValue
    {
        self.aggregate(.maximum, key)
    }

    public func max<Field>(_ key: KeyPath<Model, Field>) -> EventLoopFuture<Field.Value>
        where Field: QueryableProperty, Field.Value: OptionalType, Field.Model == Model
    {
        self.aggregate(.maximum, key)
    }

    public func max<Field>(_ key: KeyPath<Model, Field>) -> EventLoopFuture<Field.Value>
        where Field: QueryableProperty, Field.Value: OptionalType, Field.Model == Model.IDValue
    {
        self.aggregate(.maximum, key)
    }

    public func aggregate<Field, Result>(
        _ method: DatabaseQuery.Aggregate.Method,
        _ field: KeyPath<Model, Field>,
        as type: Result.Type = Result.self
    ) -> EventLoopFuture<Result>
        where Field: QueryableProperty, Field.Model == Model, Result: Codable
    {
        self.aggregate(method, Model.path(for: field), as: Result.self)
    }

    public func aggregate<Field, Result>(
        _ method: DatabaseQuery.Aggregate.Method,
        _ field: KeyPath<Model, Field>,
        as type: Result.Type = Result.self
    ) -> EventLoopFuture<Result>
        where Field: QueryableProperty, Field.Model == Model.IDValue, Result: Codable
    {
        self.aggregate(method, Model.path(for: field), as: Result.self)
    }


    public func aggregate<Result>(
        _ method: DatabaseQuery.Aggregate.Method,
        _ field: FieldKey,
        as type: Result.Type = Result.self
    ) -> EventLoopFuture<Result>
        where Result: Codable
    {
        self.aggregate(method, [field])
    }

    public func aggregate<Result>(
        _ method: DatabaseQuery.Aggregate.Method,
        _ path: [FieldKey],
        as type: Result.Type = Result.self
    ) -> EventLoopFuture<Result>
        where Result: Codable
    {
        self.aggregate(.field(
            .extendedPath(path, schema: Model.schemaOrAlias, space: Model.spaceIfNotAliased),
            method
        ))
    }
    
    public func aggregate<Result>(
        _ aggregate: DatabaseQuery.Aggregate,
        as type: Result.Type = Result.self
    ) -> EventLoopFuture<Result>
        where Result: Codable
    {
        let copy = self.copy()
        // Remove all eager load requests otherwise we try to
        // read IDs from the aggreate reply when performing
        // the eager load subqueries.
        copy.eagerLoaders = .init()

        // Remove all sorts since they may be incompatible with aggregates.
        copy.query.sorts = []

        // Set custom action.
        copy.query.action = .aggregate(aggregate)

        let promise = self.database.eventLoop.makePromise(of: Result.self)
        copy.run { output in
            do {
                let result = try output.decode(.aggregate, as: Result.self)
                promise.succeed(result)
            } catch {
                promise.fail(error)
            }
        }.cascadeFailure(to: promise)
        return promise.futureResult
    }
}
