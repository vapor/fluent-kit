public protocol AnyModel {
    static var entity: String { get }
}

extension AnyModel {
    public static var entity: String {
        return "\(Self.self)"
    }
}

extension Model {
    public typealias Row = ModelRow<Self>
    
    public static func find(_ id: Self.ID?, on database: Database) -> EventLoopFuture<Self.Row?> {
        guard let id = id else {
            return database.eventLoop.makeSucceededFuture(nil)
        }
        return database.query(Self.self).filter(\.id == id).first()
    }
}

public protocol Model: AnyModel {
    static var shared: Self { get }
    associatedtype ID: ModelID
    var id: ModelField<Self, ID> { get }
}

extension Model {
    public static func new() -> Row {
        return .init()
    }
}

extension Model {
    internal var all: [ModelProperty] {
        return Mirror(reflecting: self)
            .children
            .compactMap { $0.value as? ModelProperty }
    }
}

extension Model {
    public typealias Field<Value> = ModelField<Self, Value>
        where Value: Codable
    
    public typealias FieldKey<Value> = KeyPath<Self, Field<Value>>
        where Value: Codable
    
    public static func field<T>(forKey key: FieldKey<T>) -> Field<T> {
        return self.shared[keyPath: key]
    }
}

extension ModelRow {
    public func save(on database: Database) -> EventLoopFuture<Void> {
        return database.save(self)
    }
    
    public func create(on database: Database) -> EventLoopFuture<Void> {
        return database.create(self)
    }
    
    public func update(on database: Database) -> EventLoopFuture<Void> {
        return database.update(self)
    }
    
    public func delete(on database: Database) -> EventLoopFuture<Void> {
        return database.delete(self)
    }
}

#warning("TODO: possible to extend array of model?")
extension Database {
    public func create<Model>(_ models: [Model.Row]) -> EventLoopFuture<Void>
        where Model: FluentKit.Model
    {
        let builder = self.query(Model.self)
        models.forEach { model in
            precondition(!model.exists)
            builder.set(model.storage.input)
        }
        builder.query.action = .create
        var it = models.makeIterator()
        return builder.run { created in
            let next = it.next()!
            next.storage.exists = true
        }
    }
}

private extension Database {
    func save<Model>(_ model: Model.Row) -> EventLoopFuture<Void>
        where Model: FluentKit.Model
    {
        if model.exists {
            return self.update(model)
        } else {
            return self.create(model)
        }
    }
    
    func create<Model>(_ model: Model.Row) -> EventLoopFuture<Void>
        where Model: FluentKit.Model
    {
        precondition(!model.exists)
        let builder = self.query(Model.self).set(model.storage.input)
        builder.query.action = .create
        return builder.run { created in
            #warning("for mysql, we might need to hold onto storage input")
            model[\.id] = try created.storage.output!.decode(field: "fluentID", as: Model.ID.self)
            model.storage.exists = true
        }
    }
    
    func update<Model>(_ model: Model.Row) -> EventLoopFuture<Void>
        where Model: FluentKit.Model
    {
        precondition(model.exists)
        let builder = self.query(Model.self).filter(\.id == model[\.id]).set(model.storage.input)
        builder.query.action = .update
        return builder.run { updated in
            // ignore
        }
    }
    
    func delete<Model>(_ model: Model.Row) -> EventLoopFuture<Void>
        where Model: FluentKit.Model
    {
        let builder = self.query(Model.self).filter(\.id == model[\.id])
        builder.query.action = .delete
        return builder.run().map {
            model.storage.exists = false
        }
    }
}
