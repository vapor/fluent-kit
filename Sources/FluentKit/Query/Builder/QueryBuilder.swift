import NIO

public final class QueryBuilder<Model>
    where Model: FluentKit.Model
{
    public var query: DatabaseQuery

    public let database: Database
    internal var includeDeleted: Bool
    internal var models: [Schema.Type]
    public var eagerLoaders: [AnyEagerLoader]
    
    public convenience init(database: Database) {
        self.init(
            query: .init(schema: Model.schema),
            database: database,
            models: [Model.self]
        )
    }

    private init(
        query: DatabaseQuery,
        database: Database,
        models: [Schema.Type] = [],
        eagerLoaders: [AnyEagerLoader] = [],
        includeDeleted: Bool = false
    ) {
        self.query = query
        self.database = database
        self.models = models
        self.eagerLoaders = eagerLoaders
        self.includeDeleted = includeDeleted
        // Pass through custom ID key for database if used.
        let idKey = Model()._$id.key
        switch idKey {
        case .id: break
        default:
            self.query.customIDKey = idKey
        }
    }

    public func copy() -> QueryBuilder<Model> {
        .init(
            query: self.query,
            database: self.database,
            models: self.models,
            eagerLoaders: self.eagerLoaders,
            includeDeleted: self.includeDeleted
        )
    }

    // MARK: Fields

    public func field<Field>(_ field: KeyPath<Model, Field>) -> Self
        where Field: FieldProtocol, Field.Model == Model
    {
        self.field(Model.self, field)
    }

    public func field<Joined, Field>(_ joined: Joined.Type, _ field: KeyPath<Joined, Field>) -> Self
        where Joined: Schema, Field: FieldProtocol, Field.Model == Joined
    {
        self.fields(Joined.self, .key(for: field))
    }

    public func fields(_ fields: FieldKey...) -> Self {
        self.fields(Model.self, fields)
    }

    public func fields(_ fields: [FieldKey]) -> Self {
        self.fields(Model.self, fields)
    }

    public func fields<Joined>(_ joined: Joined.Type, _ fields: FieldKey...) -> Self
        where Joined: Schema
    {
        self.fields(Joined.self, fields)
    }

    public func fields<Joined>(_ joined: Joined.Type, _ fields: [FieldKey]) -> Self
        where Joined: Schema
    {
        self.query.fields += fields.map { .field($0, schema: Joined.schema) }
        return self
    }

    // MARK: Soft Delete

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
    
    public func delete() -> EventLoopFuture<Void> {
        self.query.action = .delete
        return self.run()
    }

    // MARK: Limit

    public func limit(_ count: Int) -> Self {
        self.query.limits.append(.count(count))
        return self
    }

    // MARK: Offset

    public func offset(_ count: Int) -> Self {
        self.query.offsets.append(.count(count))
        return self
    }

    // MARK: Unqiue

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

    public func all<Field>(_ key: KeyPath<Model, Field>) -> EventLoopFuture<[Field.FieldValue]>
        where
            Field: FieldProtocol,
            Field.Model == Model,
            Field.FieldValue == Field.Value
    {
        let copy = self.copy()
        copy.query.fields = [.field(Model.key(for: key), schema: Model.schema)]
        return copy.all().map {
            $0.map {
                $0[keyPath: key].fieldValue
            }
        }
    }

    public func all<Joined, Field>(
        _ joined: Joined.Type,
        _ field: KeyPath<Joined, Field>
    ) -> EventLoopFuture<[Field.FieldValue]>
        where
            Joined: Schema,
            Field: FieldProtocol,
            Field.Model == Joined,
            Field.FieldValue == Field.Value
    {
        let copy = self.copy()
        copy.query.fields = [.field(.key(for: field), schema: Joined.schemaOrAlias)]
        return copy.all().flatMapThrowing {
            try $0.map {
                try $0.joined(Joined.self)[keyPath: field].fieldValue
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
                try model.output(from: output.schema(Model.schema))
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
                return .andAllSync(self.eagerLoaders.map { eagerLoad in
                    { eagerLoad.anyRun(models: all, on: self.database) }
                }, on: self.database.eventLoop)
            }
        } else {
            return done
        }
    }

    internal func action(_ action: DatabaseQuery.Action) -> Self {
        self.query.action = action
        return self
    }

    internal func run(_ onOutput: @escaping (DatabaseOutput) -> ()) -> EventLoopFuture<Void> {
        // make a copy of this query before mutating it
        // so that run can be called multiple times
        var query = self.query

        // If fields are not being manually selected,
        // add fields from all models being queried.
        if query.fields.isEmpty {
            for model in self.models {
                query.fields += model.keys.map { key in
                    .field(key, schema: model.schemaOrAlias)
                }
            }
        }
        
        // If deleted models aren't included, add filters
        // to exclude them for each model being queried.
        if !self.includeDeleted {
            for model in self.models {
                model.excludeDeleted(from: &query)
            }
        }
        
        self.database.logger.info("\(self.query)")

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
}
