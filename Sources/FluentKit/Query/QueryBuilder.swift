import NIO

extension Database {
    public func query<Model>(_ model: Model.Type) -> QueryBuilder<Model>
        where Model: FluentKit.Model
    {
        return .init(database: self)
    }
}

public final class QueryBuilder<Model>
    where Model: FluentKit.Model
{
    let database: Database
    public var query: DatabaseQuery
    var eagerLoads: [String: EagerLoad]
    
    public init(database: Database) {
        self.database = database
        self.query = .init(entity: Model().entity)
        self.eagerLoads = [:]
        self.query.fields = Model().properties.map { .field(
            path: [$0.name],
            entity: Model().entity,
            alias: nil
        ) }
    }
    
    @discardableResult
    public func count() -> EventLoopFuture<Int> {
        self.query.fields = [.aggregate(.fields(
            method: .count,
            fields: [.keyPath(\Model.id)]
        ))]
        
        return self.first().flatMapThrowing { res in
            guard let res = res else {
                fatalError("No model")
            }
            return try res.field("fluentAggregate").get()
        }
    }
    
    @discardableResult
    public func max<T>(_ field: KeyPath<Model, ModelField<Model, T>>) -> EventLoopFuture<T?> {
        self.query.fields = [.aggregate(.fields(
            method: .maximum,
            fields: [.keyPath(field)]
        ))]
        
        return self.first().flatMapThrowing { res in
            guard let res = res else {
                fatalError("No model")
            }
            return try res.field("fluentAggregate").get()
        }
    }
    
    public enum EagerLoadMethod {
        case subquery
        case join
    }
    
    
    @discardableResult
    public func with<Child>(
        _ key: KeyPath<Model, ModelChildren<Model, Child>>,
        method: EagerLoadMethod = .subquery
    ) -> Self
        where Child: FluentKit.Model
    {
        switch method {
        case .subquery:
            let id = Model()[keyPath: key].relation.appending(path: \.id)
            self.eagerLoads[Child().entity] = SubqueryChildEagerLoad<Model, Child>(id)
        case .join:
            fatalError()
        }
        return self
    }

    @discardableResult
    public func with<Parent>(
        _ key: KeyPath<Model, ModelParent<Model, Parent>>,
        method: EagerLoadMethod = .subquery
    ) -> Self
        where Parent: FluentKit.Model
    {
        switch method {
        case .subquery:
            self.eagerLoads[Parent().entity] = SubqueryParentEagerLoad<Model, Parent>(key)
            return self
        case .join:
            self.eagerLoads[Parent().entity] = JoinParentEagerLoad<Model, Parent>()
            return self.join(key)
        }
    }
    
    @discardableResult
    public func join<Parent>(_ key: KeyPath<Model, ModelParent<Model, Parent>>) -> Self {
        let l = Model()[keyPath: key].id
        let f = Parent().id
        self.query.fields += Parent().properties.map {
            .field(
                path: [$0.name],
                entity: Parent().entity,
                alias: Parent().entity + "_" + $0.name
            )
        }
        self.query.joins.append(.model(
            foreign: .field(path: [f.name], entity: Parent().entity, alias: nil),
            local: .field(path: [l.name], entity: Model().entity, alias: nil)
        ))
        return self
    }
    
    @discardableResult
    public func join<Foreign, T>(
        _ local: KeyPath<Model, ModelField<Model, T>>,
        _ foreign: KeyPath<Foreign, ModelField<Foreign, T>>
    ) -> Self
        where Foreign: FluentKit.Model
    {
        let f = Foreign()[keyPath: foreign]
        let l = Model()[keyPath: local]
        self.query.fields += Foreign().properties.map {
            return .field(
                path: [$0.name],
                entity: Foreign().entity,
                alias: Foreign().entity + "_" + $0.name
            )
        }
        self.query.joins.append(.model(
            foreign: .field(path: [f.name], entity: Foreign().entity, alias: nil),
            local: .field(path: [l.name], entity: Model().entity, alias: nil)
        ))
        return self
    }
    
    
    @discardableResult
    public func filter(_ filter: ModelFilter<Model>) -> Self {
        return self.filter(filter.filter)
    }
    
    @discardableResult
    public func filter<T>(
        _ key: KeyPath<Model, ModelField<Model, T>>,
        in value: [T]
    ) -> Self
        where T: Encodable
    {
        return self.filter(
            .keyPath(key),
            .subset(inverse: false),
            .array(value.map { .bind($0) })
        )
    }
    
    @discardableResult
    public func filter<T>(_ key: KeyPath<Model, ModelField<Model, T>>, _ method: DatabaseQuery.Filter.Method, _ value: T) -> Self
        where T: Encodable
    {
        return self.filter(.keyPath(key), method, .bind(value))
    }
    
    @discardableResult
    public func filter(_ field: DatabaseQuery.Field, _ method: DatabaseQuery.Filter.Method, _ value: DatabaseQuery.Value) -> Self {
        return self.filter(.basic(field, method, value))
    }
    
    @discardableResult
    public func filter(_ filter: DatabaseQuery.Filter) -> Self {
        self.query.filters.append(filter)
        return self
    }
    
    @discardableResult
    public func set(_ data: [String: DatabaseQuery.Value]) -> Self {
        query.fields = data.keys.map { .field(path: [$0], entity: nil, alias: nil) }
        query.input.append(.init(data.values))
        return self
    }
    
    @discardableResult
    public func set<Value>(_ field: KeyPath<Model, ModelField<Model, Value>>, to value: Value) -> Self {
        let ref = Model()
        self.query.fields = []
        query.fields.append(.field(path: [ref[keyPath: field].name], entity: nil, alias: nil))
        switch query.input.count {
        case 0: query.input = [[.bind(value)]]
        default: query.input[0].append(.bind(value))
        }
        return self
    }
    
    public func create() -> EventLoopFuture<Void> {
        #warning("model id not set this way")
        self.query.action = .delete
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
    
    public func first() -> EventLoopFuture<Model?> {
        return all().map { $0.first }
    }
    
    public func all() -> EventLoopFuture<[Model]> {
        #warning("re-use array required by run for eager loading")
        var models: [Model] = []
        return self.run { model in
            models.append(model)
        }.map { models }
    }
    
    public func run() -> EventLoopFuture<Void> {
        return self.run { _ in }
    }
    
    public func run(_ onOutput: @escaping (Model) throws -> ()) -> EventLoopFuture<Void> {
        var all: [Model] = []
        return self.database.execute(self.query) { output in
            let model = Model.init(storage: DefaultModelStorage(
                output: output,
                eagerLoads: self.eagerLoads,
                exists: true
            ))
            all.append(model)
            try onOutput(model)
        }.flatMap {
            return .andAllSucceed(self.eagerLoads.values.map { eagerLoad in
                return eagerLoad.run(all, on: self.database)
            }, on: self.database.eventLoop)
        }
    }
}

public struct ModelFilter<Model> where Model: FluentKit.Model {
    static func make<Value, Foo>(
        _ lhs: KeyPath<Model, ModelField<Foo, Value>>,
        _ method: DatabaseQuery.Filter.Method,
        _ rhs: Value
    ) -> ModelFilter {
        let field = Model()[keyPath: lhs]
        return .init(filter: .basic(
            .field(path: field.path, entity: Model().entity, alias: nil),
            method,
            .bind(rhs)
        ))
    }
    
    let filter: DatabaseQuery.Filter
    init(filter: DatabaseQuery.Filter) {
        self.filter = filter
    }
}

public func ==<Model, Foo, Value>(lhs: KeyPath<Model, ModelField<Foo, Value>>, rhs: Value) -> ModelFilter<Model> {
    return .make(lhs, .equality(inverse: false), rhs)
}
