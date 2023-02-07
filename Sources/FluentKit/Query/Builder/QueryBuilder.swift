import AsyncKit
import NIOCore

public final class QueryBuilder<Model>
    where Model: FluentKit.Model
{
    public var query: DatabaseQuery

    public let database: Database
    internal var includeDeleted: Bool
    internal var shouldForceDelete: Bool
    internal var models: [Schema.Type]
    public var eagerLoaders: [AnyEagerLoader]

    public convenience init(database: Database) {
        self.init(
            query: .init(schema: Model.schema, space: Model.space),
            database: database,
            models: [Model.self]
        )
    }

    private init(
        query: DatabaseQuery,
        database: Database,
        models: [Schema.Type] = [],
        eagerLoaders: [AnyEagerLoader] = [],
        includeDeleted: Bool = false,
        shouldForceDelete: Bool = false
    ) {
        self.query = query
        self.database = database
        self.models = models
        self.eagerLoaders = eagerLoaders
        self.includeDeleted = includeDeleted
        self.shouldForceDelete = shouldForceDelete
        // Pass through custom ID key for database if used.
        if Model().anyID is AnyQueryableProperty {
            switch Model()._$id.key {
            case .id: break
            case let other: self.query.customIDKey = other
            }
        } else {
            self.query.customIDKey = .string("")
        }
    }

    public func copy() -> QueryBuilder<Model> {
        .init(
            query: self.query,
            database: self.database,
            models: self.models,
            eagerLoaders: self.eagerLoaders,
            includeDeleted: self.includeDeleted,
            shouldForceDelete: self.shouldForceDelete
        )
    }

    // MARK: Fields
    
    @discardableResult
    public func fields<Joined>(for model: Joined.Type) -> Self 
        where Joined: Schema & Fields
    {
        self.addFields(for: Joined.self, to: &self.query)
        return self
    }

    internal func addFields(for model: (Schema & Fields).Type, to query: inout DatabaseQuery) {
        query.fields += model.keys.map { path in
            .extendedPath([path], schema: model.schemaOrAlias, space: model.spaceIfNotAliased)
        }
    }

    @discardableResult
    public func field<Field>(_ field: KeyPath<Model, Field>) -> Self
        where Field: QueryableProperty, Field.Model == Model
    {
        self.field(Model.self, field)
    }

    @discardableResult
    public func field<Joined, Field>(_ joined: Joined.Type, _ field: KeyPath<Joined, Field>) -> Self
        where Joined: Schema, Field: QueryableProperty, Field.Model == Joined
    {
        self.query.fields.append(.extendedPath(Joined.path(for: field), schema: Joined.schemaOrAlias, space: Joined.spaceIfNotAliased))
        return self
    }
    
    @discardableResult
    public func field(_ field: DatabaseQuery.Field) -> Self {
        self.query.fields.append(field)
        return self
    }

    // MARK: Soft Delete

    @discardableResult
    public func withDeleted() -> Self {
        self.includeDeleted = true
        return self
    }

    // MARK: Actions

    public func create() -> EventLoopFuture<Void> {
        self.query.action = .create
        return self.run()
    }

    public func update() -> EventLoopFuture<Void> {
        self.query.action = .update
        return self.run()
    }

    public func delete(force: Bool = false) -> EventLoopFuture<Void> {
        self.includeDeleted = force
        self.shouldForceDelete = force
        self.query.action = .delete
        return self.run()
    }

    // MARK: Limit
    
    @discardableResult
    public func limit(_ count: Int) -> Self {
        self.query.limits.append(.count(count))
        return self
    }

    // MARK: Offset

    @discardableResult
    public func offset(_ count: Int) -> Self {
        self.query.offsets.append(.count(count))
        return self
    }

    // MARK: Unqiue

    @discardableResult
    public func unique() -> Self {
        self.query.isUnique = true
        return self
    }

    // MARK: Fetch

    public func chunk(max: Int, closure: @escaping ([Result<Model, Error>]) -> ()) -> EventLoopFuture<Void> {
        var partial: [Result<Model, Error>] = []
        partial.reserveCapacity(max)
        return self.all { row in
            partial.append(row)
            if partial.count >= max {
                closure(partial)
                partial = []
            }
        }.flatMapThrowing { 
            // any stragglers
            if !partial.isEmpty {
                closure(partial)
                partial = []
            }
        }
    }

    public func first() -> EventLoopFuture<Model?> {
        return self.limit(1)
            .all()
            .map { $0.first }
    }

    public func all<Field>(_ key: KeyPath<Model, Field>) -> EventLoopFuture<[Field.Value]>
        where
            Field: QueryableProperty,
            Field.Model == Model
    {
        let copy = self.copy()
        copy.query.fields = [.extendedPath(Model.path(for: key), schema: Model.schemaOrAlias, space: Model.spaceIfNotAliased)]
        return copy.all().map {
            $0.map {
                $0[keyPath: key].value!
            }
        }
    }

    public func all<Joined, Field>(
        _ joined: Joined.Type,
        _ field: KeyPath<Joined, Field>
    ) -> EventLoopFuture<[Field.Value]>
        where
            Joined: Schema,
            Field: QueryableProperty,
            Field.Model == Joined
    {
        let copy = self.copy()
        copy.query.fields = [.extendedPath(Joined.path(for: field), schema: Joined.schemaOrAlias, space: Joined.spaceIfNotAliased)]
        return copy.all().flatMapThrowing {
            try $0.map {
                try $0.joined(Joined.self)[keyPath: field].value!
            }
        }
    }

    public func all() -> EventLoopFuture<[Model]> {
        var models: [Result<Model, Error>] = []
        return self.all { model in
            models.append(model)
        }.flatMapThrowing {
            return try models
                .map { try $0.get() }
        }
    }

    public func run() -> EventLoopFuture<Void> {
        return self.run { _ in }
    }

    public func all(_ onOutput: @escaping (Result<Model, Error>) -> ()) -> EventLoopFuture<Void> {
        var all: [Model] = []

        let done = self.run { output in
            onOutput(.init(catching: {
                let model = Model()
                try model.output(from: output.qualifiedSchema(space: Model.spaceIfNotAliased, Model.schemaOrAlias))
                all.append(model)
                return model
            }))
        }

        // if eager loads exist, run them, and update models
        if !self.eagerLoaders.isEmpty {
            return done.flatMap {
                // don't run eager loads if result set was empty
                guard !all.isEmpty else {
                    return self.database.eventLoop.makeSucceededFuture(())
                }
                // run eager loads
                return self.eagerLoaders.sequencedFlatMapEach(on: self.database.eventLoop) { loader in
                    return loader.anyRun(models: all, on: self.database)
                }
            }
        } else {
            return done
        }
    }

    @discardableResult
    internal func action(_ action: DatabaseQuery.Action) -> Self {
        self.query.action = action
        return self
    }

    public func run(_ onOutput: @escaping (DatabaseOutput) -> ()) -> EventLoopFuture<Void> {
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
        let forceDelete = Model.init().deletedTimestamp == nil
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

        self.database.logger.debug("\(self.query)")
        self.database.history?.add(self.query)

        let done = self.database.execute(query: query) { output in
            assert(
                self.database.eventLoop.inEventLoop,
                "database driver output was not on eventloop"
            )
            onOutput(output)
        }

        done.whenComplete { _ in
            assert(
                self.database.eventLoop.inEventLoop,
                "database driver output was not on eventloop"
            )
        }
        return done
    }

    private func addTimestamps(
        triggers: [TimestampTrigger],
        to query: inout DatabaseQuery
    ) {
        var data: [DatabaseQuery.Value] = []
        for case .dictionary(var nested) in query.input {
            let timestamps = Model().timestamps.filter { triggers.contains($0.trigger) }
            for timestamp in timestamps {
                // Only add timestamps if they weren't already set
                if nested[timestamp.key] == nil {
                    nested[timestamp.key] = timestamp.currentTimestampInput
                }
            }
            data.append(.dictionary(nested))
        }
        query.input = data
    }
}
