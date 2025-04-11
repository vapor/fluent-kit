import AsyncAlgorithms
import AsyncKit
import Logging
import NIOCore

public struct AsyncModelSequence<Model: FluentKit.Model>: AsyncSequence, Sendable {
    public typealias Element = Model

    private enum Backing {
        case asyncMappedModels(AsyncThrowingMapSequence<AsyncDatabaseOutputSequence, Model>)
        case collectedModels([Model])
    }

    private let backing: Backing

    init(_ backing: AsyncThrowingMapSequence<AsyncDatabaseOutputSequence, Model>) { self.backing = .asyncMappedModels(backing) }
    init(_ backing: [Model]) { self.backing = .collectedModels(backing) }

    public func makeAsyncIterator() -> AsyncIterator {
        switch self.backing {
        case .asyncMappedModels(let backing): .init(backing: backing)
        case .collectedModels(let backing): .init(backing: backing)
        }
    }

    public struct AsyncIterator: AsyncIteratorProtocol {
        public typealias Element = Model

        private enum Backing {
            case asyncMappedModels(AsyncThrowingMapSequence<AsyncDatabaseOutputSequence, Model>.AsyncIterator)
            case collectedModels([Model].Iterator)
        }

        private var backing: Backing

        init(backing: AsyncThrowingMapSequence<AsyncDatabaseOutputSequence, Model>) { self.backing = .asyncMappedModels(backing.makeAsyncIterator()) }
        init(backing: [Model]) { self.backing = .collectedModels(backing.makeIterator()) }

        public mutating func next() async throws -> Model? {
            switch self.backing {
            case .asyncMappedModels(var iterator):
                let model = try await iterator.next()
                self.backing = .asyncMappedModels(iterator)
                return model
            case .collectedModels(var iterator):
                let model = iterator.next()
                self.backing = .collectedModels(iterator)
                return model
            }
        }
    }
}

@available(*, unavailable)
extension AsyncModelSequence.AsyncIterator: Sendable {}

public final class QueryBuilder<Model>
    where Model: FluentKit.Model
{
    public var query: DatabaseQuery

    public let database: any Database
    var models: [any Schema.Type]
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
        eagerLoaders: [any AnyEagerLoader] = []
    ) {
        self.query = query
        self.database = database
        self.models = models
        self.eagerLoaders = eagerLoaders
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
            eagerLoaders: self.eagerLoaders
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

    func addFields(for model: any (Schema & Fields).Type, to query: inout DatabaseQuery) {
        query.fields += model.keys.map { path in
            .path([path], schema: model.schemaOrAlias, space: model.spaceIfNotAliased)
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
        self.query.fields.append(.path(Joined.path(for: field), schema: Joined.schemaOrAlias, space: Joined.spaceIfNotAliased))
        return self
    }
    
    @discardableResult
    public func field(_ field: DatabaseQuery.Field) -> Self {
        self.query.fields.append(field)
        return self
    }

    // MARK: Actions

    public func create() async throws {
        self.query.action = .create
        _ = try await self.run()
    }

    public func update() async throws {
        self.query.action = .update
        _ = try await self.run()
    }

    public func delete() async throws {
        self.query.action = .delete
        _ = try await self.run()
    }

    // MARK: Limit
    
    @discardableResult
    public func limit(_ count: Int) -> Self {
        self.query.limit = count
        return self
    }

    // MARK: Offset

    @discardableResult
    public func offset(_ count: Int) -> Self {
        self.query.offset = count
        return self
    }

    // MARK: Unqiue

    @discardableResult
    public func unique() -> Self {
        self.query.isUnique = true
        return self
    }

    // MARK: Fetch

    public func first() async throws -> Model? {
        for try await model in try await self.limit(1).all() {
            return model
        }
        return nil
    }

    public func all<Field>(_ key: KeyPath<Model, Field>) async throws -> AsyncMapSequence<AsyncModelSequence<Model>, Field.Value>
        where Field: QueryableProperty, Field.Model == Model
    {
        nonisolated(unsafe) let key = key
        let copy = self.copy()
        copy.query.fields = [.path(Model.path(for: key), schema: Model.schemaOrAlias, space: Model.spaceIfNotAliased)]
        return try await copy.all().map {
            $0[keyPath: key].value!
        }
    }

    public func all<Joined, Field>(
        _ joined: Joined.Type,
        _ field: KeyPath<Joined, Field>
    ) async throws -> AsyncThrowingMapSequence<AsyncModelSequence<Model>, Field.Value>
        where Joined: Schema, Field: QueryableProperty, Field.Model == Joined
    {
        nonisolated(unsafe) let field = field
        let copy = self.copy()
        copy.query.fields = [.path(Joined.path(for: field), schema: Joined.schemaOrAlias, space: Joined.spaceIfNotAliased)]
        return try await copy.all().map {
            try $0.joined(Joined.self)[keyPath: field].value!
        }
    }

    public func all() async throws -> AsyncModelSequence<Model> {
        let models = try await self.run().map { output in
            let model = Model()

            try model.output(from: output.qualifiedSchema(space: Model.spaceIfNotAliased, Model.schemaOrAlias))
            return model
        }

        if self.eagerLoaders.isEmpty {
            // If there are no eager loaders, we can directly stream the result set.
            return .init(models)
        } else {
            // Otherwise we have to collect the result set, run the eager loaders against it, and turn it back into a fake async sequence.
            let collectedModels = try await Array(models)

            for loader in self.eagerLoaders {
                try await loader.anyRun(models: collectedModels, on: self.database)
            }
            return .init(collectedModels)
        }
    }

    @discardableResult
    func action(_ action: DatabaseQuery.Action) -> Self {
        self.query.action = action
        return self
    }

    public func run() async throws -> AsyncDatabaseOutputSequence {
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

        switch query.action {
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

        return try await self.database.execute(query: query)
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
