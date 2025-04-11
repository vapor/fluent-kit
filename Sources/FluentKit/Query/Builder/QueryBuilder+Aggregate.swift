import NIOCore

extension QueryBuilder {
    // MARK: Aggregate

    public func count() async throws -> Int {
        if Model().anyID is any AnyQueryableProperty {
            try await self.count(\._$id)
        } else if let fieldsIDType = Model.IDValue.self as? any Fields.Type {
            try await self.aggregate(.count, fieldsIDType.keys.first!)
        } else {
            fatalError("Model '\(Model.self)' has neither @ID nor @CompositeID, this is not valid.")
        }
    }

    public func count<Field>(_ key: KeyPath<Model, Field>) async throws -> Int
        where Field: QueryableProperty, Field.Model == Model, Field.Value: Sendable
    {
        try await self.aggregate(.count, key, as: Int.self)
    }

    public func count<Field>(_ key: KeyPath<Model, Field>) async throws -> Int
        where Field: QueryableProperty, Field.Model == Model.IDValue, Field.Value: Sendable
    {
        try await self.aggregate(.count, key, as: Int.self)
    }

    // TODO: `Field.Value` is not always the correct result type for `SUM()`, try `.aggregate(.sum, key, as: ...)` for now
    public func sum<Field>(_ key: KeyPath<Model, Field>) async throws -> Field.Value?
        where Field: QueryableProperty, Field.Model == Model, Field.Value: Sendable
    {
        try await self.aggregate(.sum, key)
    }

    // TODO: `Field.Value` is not always the correct result type for `SUM()`, try `.aggregate(.sum, key, as: ...)` for now
    public func sum<Field>(_ key: KeyPath<Model, Field>) async throws -> Field.Value?
        where Field: QueryableProperty, Field.Model == Model.IDValue, Field.Value: Sendable
    {
        try await self.aggregate(.sum, key)
    }

    // TODO: `Field.Value` is not always the correct result type for `SUM()`, try `.aggregate(.sum, key, as: ...)` for now
    public func sum<Field>(_ key: KeyPath<Model, Field>) async throws -> Field.Value
        where Field: QueryableProperty, Field.Value: OptionalType & Sendable, Field.Model == Model
    {
        try await self.aggregate(.sum, key)
    }

    // TODO: `Field.Value` is not always the correct result type for `SUM()`, try `.aggregate(.sum, key, as: ...)` for now
    public func sum<Field>(_ key: KeyPath<Model, Field>) async throws -> Field.Value
        where Field: QueryableProperty, Field.Value: OptionalType & Sendable, Field.Model == Model.IDValue
    {
        try await self.aggregate(.sum, key)
    }

    // TODO: `Field.Value` is not always the correct result type for `AVG()`, try `.aggregate(.average, key, as: ...)` for now
    public func average<Field>(_ key: KeyPath<Model, Field>) async throws -> Field.Value?
        where Field: QueryableProperty, Field.Model == Model, Field.Value: Sendable
    {
        try await self.aggregate(.average, key)
    }

    // TODO: `Field.Value` is not always the correct result type for `AVG()`, try `.aggregate(.average, key, as: ...)` for now
    public func average<Field>(_ key: KeyPath<Model, Field>) async throws -> Field.Value?
        where Field: QueryableProperty, Field.Model == Model.IDValue, Field.Value: Sendable
    {
        try await self.aggregate(.average, key)
    }

    // TODO: `Field.Value` is not always the correct result type for `AVG()`, try `.aggregate(.average, key, as: ...)` for now
    public func average<Field>(_ key: KeyPath<Model, Field>) async throws -> Field.Value
        where Field: QueryableProperty, Field.Value: OptionalType & Sendable, Field.Model == Model
    {
        try await self.aggregate(.average, key)
    }

    // TODO: `Field.Value` is not always the correct result type for `AVG()`, try `.aggregate(.average, key, as: ...)` for now
    public func average<Field>(_ key: KeyPath<Model, Field>) async throws -> Field.Value
        where Field: QueryableProperty, Field.Value: OptionalType & Sendable, Field.Model == Model.IDValue
    {
        try await self.aggregate(.average, key)
    }

    public func min<Field>(_ key: KeyPath<Model, Field>) async throws -> Field.Value?
        where Field: QueryableProperty, Field.Model == Model, Field.Value: Sendable
    {
        try await self.aggregate(.minimum, key)
    }

    public func min<Field>(_ key: KeyPath<Model, Field>) async throws -> Field.Value?
        where Field: QueryableProperty, Field.Model == Model.IDValue, Field.Value: Sendable
    {
        try await self.aggregate(.minimum, key)
    }

    public func min<Field>(_ key: KeyPath<Model, Field>) async throws -> Field.Value
        where Field: QueryableProperty, Field.Value: OptionalType & Sendable, Field.Model == Model
    {
        try await self.aggregate(.minimum, key)
    }

    public func min<Field>(_ key: KeyPath<Model, Field>) async throws -> Field.Value
        where Field: QueryableProperty, Field.Value: OptionalType & Sendable, Field.Model == Model.IDValue
    {
        try await self.aggregate(.minimum, key)
    }

    public func max<Field>(_ key: KeyPath<Model, Field>) async throws -> Field.Value?
        where Field: QueryableProperty, Field.Model == Model, Field.Value: Sendable
    {
        try await self.aggregate(.maximum, key)
    }

    public func max<Field>(_ key: KeyPath<Model, Field>) async throws -> Field.Value?
        where Field: QueryableProperty, Field.Model == Model.IDValue, Field.Value: Sendable
    {
        try await self.aggregate(.maximum, key)
    }

    public func max<Field>(_ key: KeyPath<Model, Field>) async throws -> Field.Value
        where Field: QueryableProperty, Field.Value: OptionalType & Sendable, Field.Model == Model
    {
        try await self.aggregate(.maximum, key)
    }

    public func max<Field>(_ key: KeyPath<Model, Field>) async throws -> Field.Value
        where Field: QueryableProperty, Field.Value: OptionalType & Sendable, Field.Model == Model.IDValue
    {
        try await self.aggregate(.maximum, key)
    }

    public func aggregate<Field, Result>(
        _ method: DatabaseQuery.Aggregate.Method,
        _ field: KeyPath<Model, Field>,
        as: Result.Type = Result.self
    ) async throws -> Result
        where Field: QueryableProperty, Field.Model == Model, Result: Codable & Sendable
    {
        try await self.aggregate(method, Model.path(for: field), as: Result.self)
    }

    public func aggregate<Field, Result>(
        _ method: DatabaseQuery.Aggregate.Method,
        _ field: KeyPath<Model, Field>,
        as: Result.Type = Result.self
    ) async throws -> Result
        where Field: QueryableProperty, Field.Model == Model.IDValue, Result: Codable & Sendable
    {
        try await self.aggregate(method, Model.path(for: field), as: Result.self)
    }


    public func aggregate<Result>(
        _ method: DatabaseQuery.Aggregate.Method,
        _ field: FieldKey,
        as: Result.Type = Result.self
    ) async throws -> Result
        where Result: Codable & Sendable
    {
        try await self.aggregate(method, [field], as: Result.self)
    }

    public func aggregate<Result>(
        _ method: DatabaseQuery.Aggregate.Method,
        _ path: [FieldKey],
        as: Result.Type = Result.self
    ) async throws -> Result
        where Result: Codable & Sendable
    {
        try await self.aggregate(
            .field(
                .path(path, schema: Model.schemaOrAlias, space: Model.spaceIfNotAliased),
                method
            ),
            as: Result.self
        )
    }
    
    public func aggregate<Result>(
        _ aggregate: DatabaseQuery.Aggregate,
        as: Result.Type = Result.self
    ) async throws -> Result
        where Result: Codable & Sendable
    {
        let copy = self.copy()
        // Remove all eager load requests; otherwise we try to read IDs from the aggreate reply
        copy.eagerLoaders = .init()

        // Remove all sorts, since they may be incompatible with aggregates.
        copy.query.sorts = []

        // Set custom action.
        copy.query.action = .aggregate(aggregate)

        for try await output in try await copy.run() {
            return try output.decode(.aggregate, as: Result.self)
        }
        throw FluentError.noResults
    }
}
