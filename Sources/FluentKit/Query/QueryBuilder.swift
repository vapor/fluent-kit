import NIO

public final class QueryBuilder<Model>
    where Model: FluentKit.Model
{
    public var query: DatabaseQuery

    public let database: Database
    internal var includeDeleted: Bool
    internal var joinedModels: [JoinedModel]
    public var eagerLoaders: [AnyEagerLoader]

    struct JoinedModel {
        let model: AnyModel
        let alias: String?
    }
    
    public init(database: Database) {
        self.database = database
        self.query = .init(schema: Model.schema, idKey: Model.key(for: \._$id))
        self.eagerLoaders = []
        self.includeDeleted = false
        self.joinedModels = []
    }

    private init(
        query: DatabaseQuery,
        database: Database,
        eagerLoaders: [AnyEagerLoader],
        includeDeleted: Bool,
        joinedModels: [JoinedModel]
    ) {
        self.query = query
        self.database = database
        self.eagerLoaders = eagerLoaders
        self.includeDeleted = includeDeleted
        self.joinedModels = joinedModels
    }

    public func copy() -> QueryBuilder<Model> {
        .init(
            query: self.query,
            database: self.database,
            eagerLoaders: self.eagerLoaders,
            includeDeleted: self.includeDeleted,
            joinedModels: self.joinedModels
        )
    }

    // MARK: Soft Delete

    public func withDeleted() -> Self {
        self.includeDeleted = true
        return self
    }

    // MARK: Filter

    @discardableResult
    public func filter(_ filter: ModelValueFilter<Model>) -> Self {
        return self.filter(
            .field(path: filter.path, schema: Model.schema, alias: nil),
            filter.method,
            filter.value
        )
    }

    @discardableResult
    public func filter(_ filter: ModelFieldFilter<Model, Model>) -> Self {
        return self.filter(
            .field(path: filter.lhsPath, schema: Model.schema, alias: nil),
            filter.method,
            .field(path: filter.rhsPath, schema: Model.schema, alias: nil)
        )
    }

    @discardableResult
    public func filter<Left, Right>(_ filter: ModelFieldFilter<Left, Right>) -> Self
        where Left: FluentKit.Model, Right: FluentKit.Model
    {
        return self.filter(
            .field(path: filter.lhsPath, schema: Left.schema, alias: nil),
            filter.method,
            .field(path: filter.rhsPath, schema: Right.schema, alias: nil)
        )
    }

    @discardableResult
    public func filter<Joined, Values>(
        _ field: KeyPath<Joined, Field<Values.Element>>,
        in values: Values,
        alias: String? = nil
    ) -> Self
        where Joined: FluentKit.Model, Values: Collection, Values.Element: Codable
    {
        return self.filter(Joined.self, Joined.key(for: field), in: values, alias: alias)
    }
    
    @discardableResult
    public func filter<Values>(_ field: KeyPath<Model, Field<Values.Element>>, in values: Values) -> Self
        where Values: Collection, Values.Element: Codable
    {
        return self.filter(Model.self, Model.key(for: field), in: values, alias: nil)
    }

    @discardableResult
    public func filter<Values>(_ fieldName: String, in values: Values) -> Self
        where Values: Collection, Values.Element: Codable
    {
        return self.filter(Model.self, fieldName, in: values, alias: nil)
    }

    @discardableResult
    public func filter<Joined, Values>(
        _ joined: Joined.Type,
        _ fieldName: String,
        in values: Values,
        alias: String? = nil
    ) -> Self
        where Joined: FluentKit.Model, Values: Collection, Values.Element: Codable
    {
        return self.filter(
            .field(
                path: [fieldName],
                schema: alias ?? Joined.schema,
                alias: nil
            ),
            .subset(inverse: false),
            .array(values.map { .bind($0) })
        )
    }

    @discardableResult
    public func filter<Alias>(_ alias: Alias.Type, _ filter: ModelValueFilter<Alias.Model>) -> Self
        where Alias: ModelAlias
    {
        return self.filter(
            .field(path: filter.path, schema: Alias.alias, alias: nil),
            filter.method,
            filter.value
        )
    }

    @discardableResult
    public func filter<Alias>(_ alias: Alias.Type, _ filter: ModelFieldFilter<Alias.Model, Alias.Model>) -> Self
        where Alias: ModelAlias
    {
        return self.filter(
            .field(path: filter.lhsPath, schema: Alias.alias, alias: nil),
            filter.method,
            .field(path: filter.rhsPath, schema: Alias.alias, alias: nil)
        )
    }

    @discardableResult
    public func filter<Joined>(_ alias: Joined.Type, _ filter: ModelValueFilter<Joined>) -> Self
        where Joined: FluentKit.Model
    {
        return self.filter(
            .field(path: filter.path, schema: Joined.schema, alias: nil),
            filter.method,
            filter.value
        )
    }

    @discardableResult
    public func filter<Joined>(_ alias: Joined.Type, _ filter: ModelFieldFilter<Joined, Joined>) -> Self
        where Joined: FluentKit.Model
    {
        return self.filter(
            .field(path: filter.lhsPath, schema: Joined.schema, alias: nil),
            filter.method,
            .field(path: filter.rhsPath, schema: Joined.schema, alias: nil)
        )
    }
    
    @discardableResult
    public func filter<Value>(_ field: KeyPath<Model, Field<Value>>, _ method: DatabaseQuery.Filter.Method, _ value: Value) -> Self {
        return self.filter(Model.key(for: field), method, value)
    }

    @discardableResult
    public func filter<Value>(_ lhsField: KeyPath<Model, Field<Value>>, _ method: DatabaseQuery.Filter.Method, _ rhsField: KeyPath<Model, Field<Value>>) -> Self {
        return self.filter(Model.key(for: lhsField), method, Model.key(for: rhsField))
    }
    
    @discardableResult
    public func filter<Value>(_ fieldName: String, _ method: DatabaseQuery.Filter.Method, _ value: Value) -> Self
        where Value: Codable
    {
        return self.filter(.field(
            path: [fieldName],
            schema: Model.schema,
            alias: nil
        ), method, .bind(value))
    }

    @discardableResult
    public func filter(_ lhsFieldName: String, _ method: DatabaseQuery.Filter.Method, _ rhsFieldName: String) -> Self {
        return self.filter(
            .field(path: [lhsFieldName], schema: Model.schema, alias: nil),
            method,
            .field(path: [rhsFieldName], schema: Model.schema, alias: nil)
        )
    }

    @discardableResult
    public func filter(_ field: DatabaseQuery.Field, _ method: DatabaseQuery.Filter.Method, _ value: DatabaseQuery.Value) -> Self {
        return self.filter(.value(field, method, value))
    }

    @discardableResult
    public func filter(_ lhsField: DatabaseQuery.Field, _ method: DatabaseQuery.Filter.Method, _ rhsField: DatabaseQuery.Field) -> Self {
        return self.filter(.field(lhsField, method, rhsField))
    }
    
    @discardableResult
    public func filter(_ filter: DatabaseQuery.Filter) -> Self {
        self.query.filters.append(filter)
        return self
    }
    
    @discardableResult
    public func set(_ data: [String: DatabaseQuery.Value]) -> Self {
        self.set([data])
    }

    @discardableResult
    public func set(_ data: [[String: DatabaseQuery.Value]]) -> Self {
        assert(self.query.fields.isEmpty, "Conflicting query fields already exist.")
        // ensure there is at least one
        guard let keys = data.first?.keys else {
            return self
        }
        // use first copy of keys to ensure correct ordering
        self.query.fields = keys.map { .field(path: [$0], schema: nil, alias: nil) }
        for item in data {
            let input = keys.map { item[$0]! }
            self.query.input.append(input)
        }
        return self
    }

    // MARK: Set
    
    @discardableResult
    public func set<Value>(_ field: KeyPath<Model, Field<Value>>, to value: Value) -> Self {
        self.query.fields.append(.field(path: [Model.key(for: field)], schema: nil, alias: nil))
        switch query.input.count {
        case 0: query.input = [[.bind(value)]]
        default: query.input[0].append(.bind(value))
        }
        return self
    }

    // MARK: Sort

    public func sort<Field>(_ field: KeyPath<Model, Field>, _ direction: DatabaseQuery.Sort.Direction = .ascending) -> Self
        where Field: FieldRepresentable
    {
        return self.sort(Model.self, Model.key(for: field), direction, alias: nil)
    }


    public func sort<Joined, Field>(
        _ field: KeyPath<Joined, Field>,
        _ direction: DatabaseQuery.Sort.Direction = .ascending,
        alias: String? = nil
    ) -> Self
        where Joined: FluentKit.Model, Field: FieldRepresentable
    {
        return self.sort(Joined.self, Joined.key(for: field), direction, alias: alias)
    }

    public func sort(_ field: String, _ direction: DatabaseQuery.Sort.Direction = .ascending) -> Self {
        return self.sort(Model.self, field, direction, alias: nil)
    }

    public func sort<Joined>(
        _ model: Joined.Type,
        _ field: String,
        _ direction: DatabaseQuery.Sort.Direction = .ascending,
        alias: String? = nil
    ) -> Self
        where Joined: FluentKit.Model
    {
        self.query.sorts.append(.sort(field: .field(
            path: [field],
            schema: alias ?? Joined.schema,
            alias: nil
        ), direction: direction))
        return self
    }

    // MARK: Nested

    public func filter<Value, NestedValue>(
        _ field: KeyPath<Model, Field<Value>>,
        _ path: NestedPath,
        _ method: DatabaseQuery.Filter.Method,
        _ value: NestedValue
    ) -> Self
        where Value: Codable, NestedValue: Codable
    {
        return self.filter(Model.key(for: field), path, method, value)
    }

    public func filter<NestedValue>(
        _ fieldName: String,
        _ path: NestedPath,
        _ method: DatabaseQuery.Filter.Method,
        _ value: NestedValue
    ) -> Self
        where NestedValue: Codable
    {
        let field: DatabaseQuery.Field = .field(
            path: [fieldName] + path.path,
            schema: Model.schema,
            alias: nil
        )
        return self.filter(field, method, .bind(value))
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
    
    
    // MARK: Aggregate

    public func count() -> EventLoopFuture<Int> {
        return self.aggregate(.count, Model.key(for: \Model._$id), as: Int.self)
    }

    public func sum<Field>(_ key: KeyPath<Model, Field>) -> EventLoopFuture<Field.Value?>
        where Field: FieldRepresentable
    {
        return self.aggregate(.sum, key)
    }

    public func sum<Field>(_ key: KeyPath<Model, Field>) -> EventLoopFuture<Field.Value>
        where Field: FieldRepresentable, Field.Value: OptionalType
    {
        return self.aggregate(.sum, key)
    }

    public func average<Field>(_ key: KeyPath<Model, Field>) -> EventLoopFuture<Field.Value?>
        where Field: FieldRepresentable
    {
        return self.aggregate(.average, key)
    }

    public func average<Field>(_ key: KeyPath<Model, Field>) -> EventLoopFuture<Field.Value>
        where Field: FieldRepresentable, Field.Value: OptionalType
    {
        return self.aggregate(.average, key)
    }

    public func min<Field>(_ key: KeyPath<Model, Field>) -> EventLoopFuture<Field.Value?>
        where Field: FieldRepresentable
    {
        return self.aggregate(.minimum, key)
    }

    public func min<Field>(_ key: KeyPath<Model, Field>) -> EventLoopFuture<Field.Value>
        where Field: FieldRepresentable, Field.Value: OptionalType
    {
        return self.aggregate(.minimum, key)
    }

    public func max<Field>(_ key: KeyPath<Model, Field>) -> EventLoopFuture<Field.Value?>
        where Field: FieldRepresentable
    {
        return self.aggregate(.maximum, key)
    }

    public func max<Field>(_ key: KeyPath<Model, Field>) -> EventLoopFuture<Field.Value>
        where Field: FieldRepresentable, Field.Value: OptionalType
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
    
    public func all() -> EventLoopFuture<[Model]> {
        var models: [Result<Model, Error>] = []
        return self.all { model in
            models.append(model)
        }.flatMapThrowing {
            return try models
                .map { try $0.get() }
        }
    }

    internal func action(_ action: DatabaseQuery.Action) -> Self {
        self.query.action = action
        return self
    }
    
    public func run() -> EventLoopFuture<Void> {
        return self.run { _ in }
    }
    
    public func all(_ onOutput: @escaping (Result<Model, Error>) -> ()) -> EventLoopFuture<Void> {
        var all: [Model] = []

        let done = self.run { output in
            onOutput(.init(catching: {
                let model = Model()
                try model.output(from: output)
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

    func run(_ onOutput: @escaping (DatabaseOutput) -> ()) -> EventLoopFuture<Void> {
        // make a copy of this query before mutating it
        // so that run can be called multiple times
        var query = self.query

        if query.fields.isEmpty {
            // default fields
            query.fields = Model().fields.map { (_, field) in
                return .field(
                    path: [field.key],
                    schema: Model.schema,
                    alias: nil
                )
            }
            for joined in self.joinedModels {
                query.fields += joined.model.fields.map { (_, field) in
                    return .field(
                        path: [field.key],
                        schema: joined.alias ?? type(of: joined.model).schema,
                        alias: (joined.alias ?? type(of: joined.model).schema) + "_" + field.key
                    )
                }
            }
        }
        
        // check if model is soft-deletable and should be excluded
        if !self.includeDeleted {
            Model().excludeDeleted(from: &query)
            self.joinedModels
                .forEach { $0.model.excludeDeleted(from: &query) }
        }
        
        self.database.logger.info("\(self.query)")

        let done = self.database.execute(query: query) { row in
            assert(self.database.eventLoop.inEventLoop,
                   "database driver output was not on eventloop")
            onOutput(row.output(for: self.database))
        }
        
        done.whenComplete { _ in
            assert(self.database.eventLoop.inEventLoop,
                   "database driver output was not on eventloop")
        }
        
        return done
    }
}

public struct NestedPath: ExpressibleByStringLiteral {
    public var path: [String]
    
    public init(path: [String]) {
        self.path = path
    }

    public init(stringLiteral value: String) {
        self.path = value.split(separator: ".").map(String.init)
    }
}


