import NIO

//extension Database {
//    public func query<Model>(_ model: Model.Type) -> QueryBuilder<Model>
//        where Model: FluentKit.Model
//    {
//        return .init(database: self)
//    }
//}

public final class QueryBuilder<Model>
    where Model: FluentKit.Model
{
    public var query: DatabaseQuery

    public let database: Database
    internal var eagerLoads: EagerLoads
    internal var includeSoftDeleted: Bool
    internal var joinedModels: [AnyModel]
    
    public init(database: Database) {
        self.database = database
        self.query = .init(entity: Model.entity)
        self.eagerLoads = .init()
        self.query.fields = Model().fields.map { (label, field) in
            return .field(
                path: [field.key(label: label)],
                entity: Model.entity,
                alias: nil
            )
        }
        self.includeSoftDeleted = false
        self.joinedModels = []
    }

    // MARK: Eager Load
    
    @discardableResult
    public func eagerLoad<Value>(_ field: KeyPath<Model, Children<Model, Value>>, method: EagerLoadMethod = .subquery) -> Self {
        let ref = Model()
        let property = ref[keyPath: field]
        property.eagerLoad(to: self.eagerLoads, method: method, label: ref.label(for: property))
        return self
    }

    @discardableResult
    public func eagerLoad<Value>(_ field: KeyPath<Model, Parent<Value>>, method: EagerLoadMethod = .subquery) -> Self {
        let ref = Model()
        let property = ref[keyPath: field]
        property.eagerLoad(to: self.eagerLoads, method: method, label: ref.label(for: property))
        return self
    }

    // MARK: Soft Delete

    public func withSoftDeleted() -> Self {
        self.includeSoftDeleted = true
        return self
    }

    // MARK: Join
    
    @discardableResult
    public func join<Value>(_ field: KeyPath<Model, Parent<Value>>) -> Self
        where Value: FluentKit.Model
    {
        return self.join(
            Value.self, Value.key(for: \Value.idField),
            to: Model.self, Model.key(for: field),
            method: .inner
        )
    }

    @discardableResult
    public func join<Foreign, Local, Value>(
        _ foreign: KeyPath<Foreign, Field<Value?>>,
        to local: KeyPath<Local, Field<Value>>,
        method: DatabaseQuery.Join.Method = .inner
    ) -> Self
        where Foreign: FluentKit.Model, Local: FluentKit.Model
    {
        return self.join(
            Foreign.self, Foreign.key(for: foreign),
            to: Local.self, Local.key(for: local),
            method: .inner
        )
    }

    @discardableResult
    public func join<Foreign, Local, Value>(
        _ foreign: KeyPath<Foreign, Field<Value>>,
        to local: KeyPath<Local, Field<Value?>>,
        method: DatabaseQuery.Join.Method = .inner
    ) -> Self
        where Foreign: FluentKit.Model, Local: FluentKit.Model
    {
        return self.join(
            Foreign.self, Foreign.key(for: foreign),
            to: Local.self, Local.key(for: local),
            method: .inner
        )
    }

    @discardableResult
    public func join<Foreign, Local, Value>(
        _ foreign: KeyPath<Foreign, Field<Value>>,
        to local: KeyPath<Local, Field<Value>>,
        method: DatabaseQuery.Join.Method = .inner
    ) -> Self
        where Foreign: FluentKit.Model, Local: FluentKit.Model
    {
        return self.join(
            Foreign.self, Foreign.key(for: foreign),
            to: Local.self, Local.key(for: local),
            method: .inner
        )
    }
    
    @discardableResult
    public func join<Foreign, Local>(
        _ foreign: Foreign.Type,
        _ foreignField: String,
        to local: Local.Type,
        _ localField: String,
        method: DatabaseQuery.Join.Method = .inner
    ) -> Self
        where Foreign: FluentKit.Model, Local: FluentKit.Model
    {
        self.query.fields += Foreign().fields.map { (label, field) in
            return .field(
                path: [field.key(label: label)],
                entity: Foreign.entity,
                alias: Foreign.entity + "_" + field.key(label: label)
            )
        }
        self.joinedModels.append(Foreign())
        self.query.joins.append(.model(
            foreign: .field(path: [foreignField], entity: Foreign.entity, alias: nil),
            local: .field(path: [localField], entity: Local.entity, alias: nil),
            method: method
        ))
        return self
    }

    // MARK: Filter
    
    @discardableResult
    public func filter(_ filter: ModelFilter<Model>) -> Self {
        return self.filter(filter.filter)
    }

    @discardableResult
    public func filter<Joined>(_ filter: ModelFilter<Joined>) -> Self
        where Joined: FluentKit.Model
    {
        return self.filter(filter.filter)
    }
    
    @discardableResult
    public func filter<Value>(_ field: KeyPath<Model, Field<Value>>, in values: [Value]) -> Self {
        return self.filter(Model.key(for: field), in: values)
    }
    
    @discardableResult
    public func filter<Value>(_ fieldName: String, in values: [Value]) -> Self
        where Value: Codable
    {
        return self.filter(.field(path: [fieldName], entity: Model.entity, alias: nil), .subset(inverse: false), .array(values.map { .bind($0) })
        )
    }
    
    @discardableResult
    public func filter<Value>(_ field: KeyPath<Model, Field<Value>>, _ method: DatabaseQuery.Filter.Method, _ value: Value) -> Self {
        return self.filter(Model.key(for: field), method, value)
    }
    
    @discardableResult
    public func filter<Value>(_ fieldName: String, _ method: DatabaseQuery.Filter.Method, _ value: Value) -> Self
        where Value: Codable
    {
        return self.filter(.field(path: [fieldName], entity: Model.entity, alias: nil), method, .bind(value))
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
        self.query.fields = data.keys.map { .field(path: [$0], entity: nil, alias: nil) }
        self.query.input.append(.init(data.values))
        return self
    }

    @discardableResult
    public func set(_ data: [[String: DatabaseQuery.Value]]) -> Self {
        // ensure there is at least one
        guard let keys = data.first?.keys else {
            return self
        }
        // use first copy of keys to ensure correct ordering
        self.query.fields = keys.map { .field(path: [$0], entity: nil, alias: nil) }
        for item in data {
            let input = keys.map { item[$0]! }
            self.query.input.append(input)
        }
        return self
    }

    // MARK: Set
    
    @discardableResult
    public func set<Value>(_ field: KeyPath<Model, Field<Value>>, to value: Value) -> Self {
        self.query.fields = []
        query.fields.append(.field(path: [Model.key(for: field)], entity: nil, alias: nil))
        switch query.input.count {
        case 0: query.input = [[.bind(value)]]
        default: query.input[0].append(.bind(value))
        }
        return self
    }

    // MARK: Sort

    /// Add a sort to the query builder for a field.
    ///
    ///     Planet.query(on: db).sort(\.name, .descending)
    ///
    /// - parameters:
    ///     - key: Swift `KeyPath` to field on model to sort.
    ///     - direction: Direction to sort the fields, ascending or descending.
    /// - returns: Query builder for chaining.
    public func sort<Value>(_ field: KeyPath<Model, Field<Value>>, _ direction: DatabaseQuery.Sort.Direction = .ascending) -> Self {
        return self.sort(Model.self, Model.key(for: field), direction)
    }

    /// Add a sort to the query builder for a field.
    ///
    ///     Planet.query(on: db).join(\.galaxy).sort(\Galaxy.name, .ascending)
    ///
    /// - parameters:
    ///     - key: Swift `KeyPath` to field on model to sort.
    ///     - direction: Direction to sort the fields, ascending or descending.
    /// - returns: Query builder for chaining.
    public func sort<Joined, Value>(_ field: KeyPath<Joined, Field<Value>>, _ direction: DatabaseQuery.Sort.Direction = .ascending) -> Self
        where Joined: FluentKit.Model
    {
        return self.sort(Joined.self, Joined.key(for: field), direction)
    }

    public func sort(_ field: String, _ direction: DatabaseQuery.Sort.Direction = .ascending) -> Self {
        return self.sort(Model.self, field, direction)
    }

    public func sort<Joined>(_ model: Joined.Type, _ field: String, _ direction: DatabaseQuery.Sort.Direction = .ascending) -> Self
        where Joined: FluentKit.Model
    {
        self.query.sorts.append(.sort(field: .field(path: [field], entity: Joined.entity, alias: nil), direction: direction))
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
        let field: DatabaseQuery.Field = .field(path: [fieldName] + path.path, entity: Model.entity, alias: nil)
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
        return self.aggregate(.count, Model.key(for: \Model.idField), as: Int.self)
    }

    public func sum<Value>(_ key: KeyPath<Model, Field<Value?>>) -> EventLoopFuture<Value?>
        where Value: Codable
    {
        return self.aggregate(.sum, key)
    }
    
    public func sum<Value>(_ key: KeyPath<Model, Field<Value>>) -> EventLoopFuture<Value?>
        where Value: Codable
    {
        return self.aggregate(.sum, key)
    }

    public func average<Value>(_ key: KeyPath<Model, Field<Value?>>) -> EventLoopFuture<Value?>
        where Value: Codable
    {
        return self.aggregate(.average, key)
    }
    
    public func average<Value>(_ key: KeyPath<Model, Field<Value>>) -> EventLoopFuture<Value?>
        where Value: Codable
    {
        return self.aggregate(.average, key)
    }

    public func min<Value>(_ key: KeyPath<Model, Field<Value?>>) -> EventLoopFuture<Value?>
        where Value: Codable
    {
        return self.aggregate(.minimum, key)
    }
    
    public func min<Value>(_ key:KeyPath<Model, Field<Value>>) -> EventLoopFuture<Value?>
        where Value: Codable
    {
        return self.aggregate(.minimum, key)
    }

    public func max<Value>(_ key: KeyPath<Model, Field<Value?>>) -> EventLoopFuture<Value?>
        where Value: Codable
    {
        return self.aggregate(.maximum, key)
    }
    
    public func max<Value>(_ key: KeyPath<Model, Field<Value>>) -> EventLoopFuture<Value?>
        where Value: Codable
    {
        return self.aggregate(.maximum, key)
    }


    public func aggregate<Value, Result>(
        _ method: DatabaseQuery.Field.Aggregate.Method,
        _ field: KeyPath<Model, Field<Value>>,
        as type: Result.Type = Result.self
    ) -> EventLoopFuture<Result>
        where Result: Codable
    {
        return self.aggregate(method, Model.key(for: field), as: Result.self)
    }
    
    public func aggregate<Result>(
        _ method: DatabaseQuery.Field.Aggregate.Method,
        _ fieldName: String,
        as type: Result.Type = Result.self
    ) -> EventLoopFuture<Result>
        where Result: Codable
    {
        self.query.fields = [.aggregate(.fields(
            method: method,
            fields: [.field(path: [fieldName], entity: Model.entity, alias: nil)]
        ))]
        
        return self.first().flatMapThrowing { res in
            guard let res = res else {
                fatalError("No model")
            }
            return try res.idField.cachedOutput!.decode(field: "fluentAggregate", as: Result.self)
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
    
    public func chunk(max: Int, closure: @escaping ([Model]) throws -> ()) -> EventLoopFuture<Void> {
        var partial: [Model] = []
        partial.reserveCapacity(max)
        return self.all { row in
            partial.append(row)
            if partial.count >= max {
                try closure(partial)
                partial = []
            }
        }.flatMapThrowing { 
            // any stragglers
            if !partial.isEmpty {
                try closure(partial)
                partial = []
            }
        }
    }
    
    public func first() -> EventLoopFuture<Model?> {
        var model: Model? = nil
        return self.limit(1)
            .all { result in
                assert(model == nil, "unexpected database output")
                model = result
            }
            .map { model }
    }
    
    public func all() -> EventLoopFuture<[Model]> {
        var models: [Model] = []
        return self.all { model in
            models.append(model)
        }.map { models }
    }

    internal func action(_ action: DatabaseQuery.Action) -> Self {
        self.query.action = action
        return self
    }
    
    public func run() -> EventLoopFuture<Void> {
        return self.run { _ in }
    }
    
    public func all(_ onOutput: @escaping (Model) throws -> ()) -> EventLoopFuture<Void> {
        var all: [Model] = []

        let done = self.run { output in
            let model = Model()
            try model.output(from: output)
            all.append(model)
            try onOutput(model)
        }

        // if eager loads exist, run them, and update models
        if !self.eagerLoads.requests.isEmpty {
            return done.flatMap {
                return .andAllSucceed(self.eagerLoads.requests.values.map { eagerLoad in
                    return eagerLoad.run(models: all, on: self.database)
                }, on: self.database.eventLoop)
            }.flatMapThrowing {
                try all.forEach { model in
                    try model.eagerLoad(from: self.eagerLoads)
                }
            }
        } else {
            return done
        }
    }

    func run(_ onOutput: @escaping (DatabaseOutput) throws -> ()) -> EventLoopFuture<Void> {

        // make a copy of this query before mutating it
        // so that run can be called multiple times
        var query = self.query

        // prepare all eager load requests
        self.eagerLoads.requests.values.forEach { $0.prepare(query: &query) }
        
        // check if model is soft-deletable and should be excluded
        if let softDeletable = Model() as? _AnySoftDeletable, !self.includeSoftDeleted {
            softDeletable._excludeSoftDeleted(&query)
            self.joinedModels
                .compactMap { $0 as? _AnySoftDeletable }
                .forEach { $0._excludeSoftDeleted(&query) }
        }

        return self.database.execute(query) { output in
            try onOutput(output)
        }
    }
}

// MARK: Operators

public func == <Model, Value>(lhs: KeyPath<Model, Field<Value>>, rhs: Value) -> ModelFilter<Model>
    where Model: FluentKit.Model
{
    return .make(lhs, .equal, .bind(rhs))
}

public func != <Model, Value>(lhs: KeyPath<Model, Field<Value>>, rhs: Value) -> ModelFilter<Model>
    where Model: FluentKit.Model
{
    return .make(lhs, .notEqual, .bind(rhs))
}

public func >= <Model, Value>(lhs: KeyPath<Model, Field<Value>>, rhs: Value) -> ModelFilter<Model>
    where Model: FluentKit.Model
{
    return .make(lhs, .greaterThanOrEqual, .bind(rhs))
}

public func > <Model, Value>(lhs: KeyPath<Model, Field<Value>>, rhs: Value) -> ModelFilter<Model>
    where Model: FluentKit.Model
{
    return .make(lhs, .greaterThan, .bind(rhs))
}

public func < <Model, Value>(lhs: KeyPath<Model, Field<Value>>, rhs: Value) -> ModelFilter<Model>
    where Model: FluentKit.Model
{
    return .make(lhs, .lessThan, .bind(rhs))
}

public func <= <Model, Value>(lhs: KeyPath<Model, Field<Value>>, rhs: Value) -> ModelFilter<Model>
    where Model: FluentKit.Model
{
    return .make(lhs, .lessThanOrEqual, .bind(rhs))
}

infix operator ~~
public func ~~ <Model, Value>(lhs: KeyPath<Model, Field<Value>>, rhs: [Value]) -> ModelFilter<Model>
    where Model: FluentKit.Model
{
    return .make(lhs, .subset(inverse: false), .array(rhs.map { .bind($0) }))
}

infix operator !~
public func !~ <Model, Value>(lhs: KeyPath<Model, Field<Value>>, rhs: [Value]) -> ModelFilter<Model>
    where Model: FluentKit.Model
{
    return .make(lhs, .subset(inverse: true), .array(rhs.map { .bind($0) }))
}


public func ~= <Model, Value>(lhs: KeyPath<Model, Field<Value>>, rhs: Value) -> ModelFilter<Model>
    where Model: FluentKit.Model, Value: CustomStringConvertible
{
    return .make(lhs, .contains(inverse: false, .suffix), .bind(rhs))
}

public func ~~ <Model, Value>(lhs: KeyPath<Model, Field<Value>>, rhs: Value) -> ModelFilter<Model>
    where Model: FluentKit.Model, Value: CustomStringConvertible
{
    return .make(lhs, .contains(inverse: false, .anywhere), .bind(rhs))
}

infix operator =~
public func =~ <Model, Value>(lhs: KeyPath<Model, Field<Value>>, rhs: Value) -> ModelFilter<Model>
    where Model: FluentKit.Model, Value: CustomStringConvertible
{
    return .make(lhs, .contains(inverse: false, .prefix), .bind(rhs))
}


infix operator !~=
public func !~= <Model, Value>(lhs: KeyPath<Model, Field<Value>>, rhs: Value) -> ModelFilter<Model>
    where Model: FluentKit.Model, Value: CustomStringConvertible
{
    return .make(lhs, .contains(inverse: true, .suffix), .bind(rhs))
}

infix operator !~~
public func !~~ <Model, Value>(lhs: KeyPath<Model, Field<Value>>, rhs: Value) -> ModelFilter<Model>
    where Model: FluentKit.Model, Value: CustomStringConvertible
{
    return .make(lhs, .contains(inverse: true, .anywhere), .bind(rhs))
}

infix operator !=~
public func !=~ <Model, Value>(lhs: KeyPath<Model, Field<Value>>, rhs: Value) -> ModelFilter<Model>
    where Model: FluentKit.Model, Value: CustomStringConvertible
{
    return .make(lhs, .contains(inverse: true, .prefix), .bind(rhs))
}

public struct ModelFilter<Model> where Model: FluentKit.Model {
    static func make<Value>(_ lhs: KeyPath<Model, Field<Value>>, _ method: DatabaseQuery.Filter.Method, _ rhs: DatabaseQuery.Value) -> ModelFilter {
        return .init(filter: .basic(
            .field(path: [Model.key(for: lhs)], entity: Model.entity, alias: nil),
            method,
            rhs
        ))
    }

    let filter: DatabaseQuery.Filter
    init(filter: DatabaseQuery.Filter) {
        self.filter = filter
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
