import NIOConcurrencyHelpers
import NIOCore

extension QueryBuilder {
    // MARK: - Actions
    public func create() async throws {
        self.query.action = .create
        return try await self.run()
    }

    public func update() async throws {
        self.query.action = .update
        return try await self.run()
    }

    public func delete(force: Bool = false) async throws {
        self.includeDeleted = force
        self.shouldForceDelete = force
        self.query.action = .delete
        return try await self.run()
    }

    // MARK: - Fetch

    public func chunk(max: Int, closure: @escaping @Sendable ([Result<Model, any Error>]) -> Void) async throws {
        nonisolated(unsafe) var partial: [Result<Model, any Error>] = []
        partial.reserveCapacity(max)

        do {
            try await self.all { row in
                partial.append(row)
                if partial.count >= max {
                    closure(partial)
                    partial.removeAll()
                }
            }
        } catch {
            if !partial.isEmpty {
                closure(partial)
            }
        }
    }

    public func first() async throws -> Model? {
        try await self.limit(1).all().first
    }

    public func all<Field>(_ key: KeyPath<Model, Field>) async throws -> [Field.Value]
        where Field: QueryableProperty, Field.Model == Model 
    {
        let copy = self.copy()
        copy.query.fields = [.extendedPath(Model.path(for: key), schema: Model.schemaOrAlias, space: Model.spaceIfNotAliased)]
        return try await copy.all().map {
            $0[keyPath: key].value!
        }

    }

    public func all<Joined, Field>(
        _ joined: Joined.Type,
        _ field: KeyPath<Joined, Field>
    ) async throws -> [Field.Value]
        where 
            Joined: Schema, 
            Field: QueryableProperty, 
            Field.Model == Joined 
    {
        let copy = self.copy()
        copy.query.fields = [.extendedPath(Joined.path(for: field), schema: Joined.schemaOrAlias, space: Joined.spaceIfNotAliased)]
        return try await copy.all().map {
            try $0.joined(Joined.self)[keyPath: field].value!
        }
    }

    public func all() async throws -> [Model] {
        nonisolated(unsafe) var models: [Result<Model, any Error>] = []
        try await self.all { models.append($0) }
        return try models.map { try $0.get() }
    }

    public func run() async throws {
        try await self.run { _ in }
    }

    public func all(_ onOutput: @escaping @Sendable (Result<Model, any Error>) -> Void) async throws {
        nonisolated(unsafe) var all: [Model] = []

        try await self.run { output in
            onOutput(.init(catching: {
                let model = Model()
                try model.output(from: output.qualifiedSchema(space: Model.spaceIfNotAliased, Model.schemaOrAlias))
                all.append(model)
                return model
            }))
        }
        // if eager loads exist, run them, and update models
        if !self.eagerLoaders.isEmpty {
            let loaders = self.eagerLoaders
            let db = self.database

            // don't run eager loads if result set was empty
            guard !all.isEmpty else { return }

            for loader in loaders {
                try await loader.anyRun(models: all, on: db).get()
            }
        }
    }

    public func run(_ onOutput: @escaping @Sendable (any DatabaseOutput) -> Void) async throws {
        // make a copy of this query before mutating it
        // so that run can be called multiple times
        var query = self.query

        // If fields are not being manually selected,
        // add fields from all models being queried.
        if query.fields.isEmpty {
            for model in self.models {
                self.addFields(for: model, to: &query)
            }
        }

        // If deleted models aren't included, add filters
        // to exclude them for each model being queried.
        if !self.includeDeleted {
            for model in self.models {
                model.excludeDeleted(from: &query)
            }
        }

        // TODO: combine this logic with model+crud timestamps
        let forceDelete =
            Model.init().deletedTimestamp == nil
            ? true : self.shouldForceDelete
        switch query.action {
        case .delete:
            if !forceDelete {
                query.action = .update
                query.input = [.dictionary([:])]
                self.addTimestamps(triggers: [.update, .delete], to: &query)
            }
        case .create:
            self.addTimestamps(triggers: [.create, .update], to: &query)
        case .update:
            self.addTimestamps(triggers: [.update], to: &query)
        default:
            break
        }

        // N.B.: We use `self.query` here instead of `query` so that the logging reflects the query the user requested,
        // without having to deal with the noise of us having added default fields, or doing deletedAt checks, etc.
        self.database.logger.debug("Running query", metadata: self.query.describedByLoggingMetadata)
        self.database.history?.add(self.query)

        return try await self.database.execute(query: query) { output in
            onOutput(output)
        }
    }

    // MARK: - Aggregate
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

    public func sum<Field>(_ key: KeyPath<Model, Field>) async throws -> Field.Value?
        where Field: QueryableProperty, Field.Model == Model, Field.Value: Sendable 
    {
        try await self.aggregate(.sum, key)
    }

    public func sum<Field>(_ key: KeyPath<Model, Field>) async throws -> Field.Value?
        where Field: QueryableProperty, Field.Model == Model.IDValue, Field.Value: Sendable 
    {
        try await self.aggregate(.sum, key)
    }

    public func sum<Field>(_ key: KeyPath<Model, Field>) async throws -> Field.Value
        where Field: QueryableProperty, Field.Value: OptionalType & Sendable, Field.Model == Model 
    {
        try await self.aggregate(.sum, key)
    }

    public func sum<Field>(_ key: KeyPath<Model, Field>) async throws -> Field.Value
        where Field: QueryableProperty, Field.Value: OptionalType & Sendable, Field.Model == Model.IDValue 
    {
        try await self.aggregate(.sum, key)
    }

    public func average<Field>(_ key: KeyPath<Model, Field>) async throws -> Field.Value?
        where Field: QueryableProperty, Field.Model == Model, Field.Value: Sendable 
    {
        try await self.aggregate(.average, key)
    }

    public func average<Field>(_ key: KeyPath<Model, Field>) async throws -> Field.Value?
        where Field: QueryableProperty, Field.Model == Model.IDValue, Field.Value: Sendable 
    {
        try await self.aggregate(.average, key)
    }

    public func average<Field>(_ key: KeyPath<Model, Field>) async throws -> Field.Value
        where Field: QueryableProperty, Field.Value: OptionalType & Sendable, Field.Model == Model 
    {
        try await self.aggregate(.average, key)
    }

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
        as type: Result.Type = Result.self
    ) async throws -> Result
        where Field: QueryableProperty, Field.Model == Model, Result: Codable & Sendable 
    {
        try await self.aggregate(method, Model.path(for: field), as: Result.self)
    }

    public func aggregate<Field, Result>(
        _ method: DatabaseQuery.Aggregate.Method,
        _ field: KeyPath<Model, Field>,
        as type: Result.Type = Result.self
    ) async throws -> Result
        where Field: QueryableProperty, Field.Model == Model.IDValue, Result: Codable & Sendable 
    {
        try await self.aggregate(method, Model.path(for: field), as: Result.self)
    }

    public func aggregate<Result>(
        _ method: DatabaseQuery.Aggregate.Method,
        _ field: FieldKey,
        as type: Result.Type = Result.self
    ) async throws -> Result
        where Result: Codable & Sendable 
    {
        try await self.aggregate(method, [field], as: Result.self)
    }

    public func aggregate<Result>(
        _ method: DatabaseQuery.Aggregate.Method,
        _ path: [FieldKey],
        as type: Result.Type = Result.self
    ) async throws -> Result
        where Result: Codable & Sendable 
    {
        try await self.aggregate(
            .field(
                .extendedPath(path, schema: Model.schemaOrAlias, space: Model.spaceIfNotAliased),
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

        copy.eagerLoaders = .init()
        copy.query.sorts = []
        copy.query.action = .aggregate(aggregate)

        nonisolated(unsafe) var output: (any DatabaseOutput)?
        try await copy.run { output = $0 }

        // In theory, this shouldn't happen, but in case it does in some edge case,
        // better to throw an error than crash with an IUO.
        guard let output else { throw RunQueryError.noDatabaseOutput }
        
        return try output.decode(.aggregate, as: Result.self)
    }

    // MARK: - Paginate
    public func paginate(
        _ request: PageRequest
    ) async throws -> Page<Model> {
        try await self.page(withIndex: request.page, size: request.per)
    }

    public func page(
        withIndex page: Int,
        size per: Int
    ) async throws -> Page<Model> {
        let trimmedRequest: PageRequest =
            if let pageSizeLimit = database.context.pageSizeLimit {
                .init(
                    page: Swift.max(page, 1),
                    per: Swift.max(Swift.min(per, pageSizeLimit), 1)
                )
            } else {
                .init(page: Swift.max(page, 1), per: Swift.max(per, 1))
            }

        let total = try await self.count()
        let items = try await self.copy().range(trimmedRequest.start..<trimmedRequest.end).all()

        return Page(
            items: items,
            metadata: .init(page: trimmedRequest.page, per: trimmedRequest.per, total: total)
        )
    }
}

enum RunQueryError: Error {
    case noDatabaseOutput
}
