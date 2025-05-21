import NIOCore
import SQLKit

public final class QueryBuilder<Model>
    where Model: FluentKit.Model
{
    public var query: DatabaseQuery

    public let database: any Database
    internal var includeDeleted: Bool
    internal var shouldForceDelete: Bool
    internal var models: [any Schema.Type]
    public var eagerLoaders: [any AnyEagerLoader]

    public convenience init(database: any Database) {
        self.init(
            query: .init(schema: Model.schema, space: Model.space),
            database: database,
            models: [Model.self]
        )
    }

    private init(
        query: DatabaseQuery,
        database: any Database,
        models: [any Schema.Type] = [],
        eagerLoaders: [any AnyEagerLoader] = [],
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
        if Model().anyID is any AnyQueryableProperty {
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

    internal func addFields(for model: any (Schema & Fields).Type, to query: inout DatabaseQuery) {
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

    public func create(annotationContext: SQLAnnotationContext?) -> EventLoopFuture<Void> {
        self.query.action = .create
        return self.run(annotationContext: annotationContext)
    }

    public func update(annotationContext: SQLAnnotationContext?) -> EventLoopFuture<Void> {
        self.query.action = .update
        return self.run(annotationContext: annotationContext)
    }

    public func delete(force: Bool = false, annotationContext: SQLAnnotationContext?) -> EventLoopFuture<Void> {
        self.includeDeleted = force
        self.shouldForceDelete = force
        self.query.action = .delete
        return self.run(annotationContext: annotationContext)
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

    public func chunk(max: Int, annotationContext: SQLAnnotationContext?, closure: @escaping @Sendable ([Result<Model, any Error>]) -> ()) -> EventLoopFuture<Void> {
        #if swift(<5.10)
        let partial: UnsafeMutableTransferBox<[Result<Model, any Error>]> = .init([])
        partial.wrappedValue.reserveCapacity(max)
        return self.all { row in
            partial.wrappedValue.append(row)
            if partial.wrappedValue.count >= max {
                closure(partial.wrappedValue)
                partial.wrappedValue.removeAll(keepingCapacity: true)
            }
        }.flatMapThrowing { 
            if !partial.wrappedValue.isEmpty {
                closure(partial.wrappedValue)
            }
        }
        #else
        nonisolated(unsafe) var partial: [Result<Model, any Error>] = []
        partial.reserveCapacity(max)
        
        return self.all(annotationContext: annotationContext) { row in
            partial.append(row)
            if partial.count >= max {
                closure(partial)
                partial.removeAll(keepingCapacity: true)
            }
        }.flatMapThrowing {
            if !partial.isEmpty {
                closure(partial)
            }
        }
        #endif
    }

    public func first(annotationContext: SQLAnnotationContext?) -> EventLoopFuture<Model?> {
        self.limit(1)
            .all(annotationContext: annotationContext)
            .map { $0.first }
    }

    public func all<Field>(_ key: KeyPath<Model, Field>, annotationContext: SQLAnnotationContext?) -> EventLoopFuture<[Field.Value]>
        where
            Field: QueryableProperty,
            Field.Model == Model
    {
        let copy = self.copy()
        copy.query.fields = [.extendedPath(Model.path(for: key), schema: Model.schemaOrAlias, space: Model.spaceIfNotAliased)]
        return copy.all(annotationContext: annotationContext).map {
            $0.map {
                $0[keyPath: key].value!
            }
        }
    }

    public func all<Joined, Field>(
        _ joined: Joined.Type,
        _ field: KeyPath<Joined, Field>,
        annotationContext: SQLAnnotationContext?
    ) -> EventLoopFuture<[Field.Value]>
        where
            Joined: Schema,
            Field: QueryableProperty,
            Field.Model == Joined
    {
        let copy = self.copy()
        copy.query.fields = [.extendedPath(Joined.path(for: field), schema: Joined.schemaOrAlias, space: Joined.spaceIfNotAliased)]
        return copy.all(annotationContext: annotationContext).flatMapThrowing {
            try $0.map {
                try $0.joined(Joined.self)[keyPath: field].value!
            }
        }
    }

    public func all(annotationContext: SQLAnnotationContext?) -> EventLoopFuture<[Model]> {
        #if swift(<5.10)
        let models: UnsafeMutableTransferBox<[Result<Model, any Error>]> = .init([])
        
        return self
            .all { models.wrappedValue.append($0) }
            .flatMapThrowing { try models.wrappedValue.map { try $0.get() } }
        #else
        nonisolated(unsafe) var models: [Result<Model, any Error>] = []

        return self
            .all(annotationContext: annotationContext) { models.append($0) }
            .flatMapThrowing { try models.map { try $0.get() } }
        #endif
    }

    public func run(annotationContext: SQLAnnotationContext?) -> EventLoopFuture<Void> {
        self.run(annotationContext: annotationContext) { _ in }
    }

    public func all(annotationContext: SQLAnnotationContext?, _ onOutput: @escaping @Sendable (Result<Model, any Error>) -> ()) -> EventLoopFuture<Void> {
        nonisolated(unsafe) var all: [Model] = []

        let done = self.run(annotationContext: annotationContext) { output in
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
            
            return done.flatMapWithEventLoop {
                // don't run eager loads if result set was empty
                guard !all.isEmpty else {
                    return $1.makeSucceededFuture(())
                }
                // run eager loads
                return loaders.reduce($1.makeSucceededVoidFuture()) { future, loader in
                    future.flatMap {
                        loader.anyRun(models: all.map { $0 }, on: db, annotationContext: annotationContext)
                    }
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

    public func run(annotationContext: SQLAnnotationContext?, _ onOutput: @escaping @Sendable (any DatabaseOutput) -> ()) -> EventLoopFuture<Void> {
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

        // N.B.: We use `self.query` here instead of `query` so that the logging reflects the query the user requested,
        // without having to deal with the noise of us having added default fields, or doing deletedAt checks, etc.
        self.database.logger.debug("Running query", metadata: self.query.describedByLoggingMetadata)
        self.database.history?.add(self.query)

        let loop = self.database.eventLoop
        
        let done = self.database.execute(query: query, annotationContext: annotationContext) { output in
            loop.assertInEventLoop()
            onOutput(output)
        }

        done.whenComplete { _ in
            loop.assertInEventLoop()
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

#if swift(<6) || !$InferSendableFromCaptures
extension Swift.KeyPath: @unchecked Swift.Sendable {}
#endif
