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
    var id: ModelField<Self, ID?> { get }
    // MARK: Lifecycle

    func willCreate(_ row: Row, on database: Database) -> EventLoopFuture<Void>
    func didCreate(_ row: Row, on database: Database) -> EventLoopFuture<Void>

    func willUpdate(_ row: Row, on database: Database) -> EventLoopFuture<Void>
    func didUpdate(_ row: Row, on database: Database) -> EventLoopFuture<Void>

    func willDelete(_ row: Row, on database: Database) -> EventLoopFuture<Void>
    func didDelete(_ row: Row, on database: Database) -> EventLoopFuture<Void>

    func willRestore(_ row: Row, on database: Database) -> EventLoopFuture<Void>
    func didRestore(_ row: Row, on database: Database) -> EventLoopFuture<Void>

    func willSoftDelete(_ row: Row, on database: Database) -> EventLoopFuture<Void>
    func didSoftDelete(_ row: Row, on database: Database) -> EventLoopFuture<Void>
}

extension Model {
    public func willCreate(_ row: Row, on database: Database) -> EventLoopFuture<Void> {
        return database.eventLoop.makeSucceededFuture(())
    }
    public func didCreate(_ row: Row, on database: Database) -> EventLoopFuture<Void> {
        return database.eventLoop.makeSucceededFuture(())
    }

    public func willUpdate(_ row: Row, on database: Database) -> EventLoopFuture<Void> {
        return database.eventLoop.makeSucceededFuture(())
    }
    public func didUpdate(_ row: Row, on database: Database) -> EventLoopFuture<Void> {
        return database.eventLoop.makeSucceededFuture(())
    }

    public func willDelete(_ row: Row, on database: Database) -> EventLoopFuture<Void> {
        return database.eventLoop.makeSucceededFuture(())
    }
    public func didDelete(_ row: Row, on database: Database) -> EventLoopFuture<Void> {
        return database.eventLoop.makeSucceededFuture(())
    }

    public func willRestore(_ row: Row, on database: Database) -> EventLoopFuture<Void> {
        return database.eventLoop.makeSucceededFuture(())
    }
    public func didRestore(_ row: Row, on database: Database) -> EventLoopFuture<Void> {
        return database.eventLoop.makeSucceededFuture(())
    }

    public func willSoftDelete(_ row: Row, on database: Database) -> EventLoopFuture<Void> {
        return database.eventLoop.makeSucceededFuture(())
    }
    public func didSoftDelete(_ row: Row, on database: Database) -> EventLoopFuture<Void> {
        return database.eventLoop.makeSucceededFuture(())
    }
}


extension Model {
    public static func new() -> Row {
        let new = Row()
        if let timestampable = Self.shared as? _AnyTimestampable {
            timestampable._initializeTimestampable(&new.storage.input)
        }
        if let softDeletable = Self.shared as? _AnySoftDeletable {
            softDeletable._initializeSoftDeletable(&new.storage.input)
        }
        return new
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
    public static func query(on database: Database) -> QueryBuilder<Self> {
        return .init(database: database)
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

extension ModelRow where Model: SoftDeletable {
    public func forceDelete(on database: Database) -> EventLoopFuture<Void> {
        return database.forceDelete(self)
    }

    public func restore(on database: Database) -> EventLoopFuture<Void> {
        return database.restore(self)
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
        if let timestampable = Model.shared as? _AnyTimestampable {
            timestampable._touchCreated(&model.storage.input)
        }
        precondition(!model.exists)
        return Model.shared.willCreate(model, on: self).flatMap {
            return self.query(Model.self)
                .set(model.storage.input)
                .action(.create)
                .run { created in
                    model[\.id] = try created.storage.output!.decode(field: "fluentID", as: Model.ID.self)
                    model.storage.exists = true
                }
        }.flatMap {
            return Model.shared.didCreate(model, on: self)
        }
    }
    
    func update<Model>(_ model: Model.Row) -> EventLoopFuture<Void>
        where Model: FluentKit.Model
    {
        if let timestampable = Model.shared as? _AnyTimestampable {
            timestampable._touchUpdated(&model.storage.input)
        }
        precondition(model.exists)
        return Model.shared.willUpdate(model, on: self).flatMap {
            return self.query(Model.self)
                .filter(\.id == model[\.id])
                .set(model.storage.input)
                .action(.update)
                .run()
        }.flatMap {
            return Model.shared.didUpdate(model, on: self)
        }
    }
    
    func delete<Model>(_ model: Model.Row) -> EventLoopFuture<Void>
        where Model: FluentKit.Model
    {
        if let softDeletable = Model.shared as? _AnySoftDeletable {
            softDeletable._clearDeletedAt(&model.storage.input)
            return Model.shared.willSoftDelete(model, on: self).flatMap {
                return self.update(model)
            }.flatMap {
                return Model.shared.didSoftDelete(model, on: self)
            }
        } else {
            return Model.shared.willDelete(model, on: self).flatMap {
                return self.query(Model.self)
                    .filter(\.id == model[\.id])
                    .action(.delete)
                    .run()
                    .map {
                        model.storage.exists = false
                    }
            }.flatMap {
                return Model.shared.didDelete(model, on: self)
            }
        }
    }

    func forceDelete<Model>(_ model: Model.Row) -> EventLoopFuture<Void>
        where Model: SoftDeletable
    {
        return Model.shared.willDelete(model, on: self).flatMap {
            return self.query(Model.self)
                .withSoftDeleted()
                .filter(\.id == model[\.id])
                .action(.delete)
                .run()
                .map {
                    model.storage.exists = false
                }
        }.flatMap {
            return Model.shared.didDelete(model, on: self)
        }
    }

    func restore<Model>(_ model: Model.Row) -> EventLoopFuture<Void>
        where Model: SoftDeletable
    {
        model[\.deletedAt] = nil
        precondition(model.exists)
        return Model.shared.willRestore(model, on: self).flatMap {
            return self.query(Model.self)
                .withSoftDeleted()
                .filter(\.id == model[\.id])
                .set(model.storage.input)
                .action(.update)
                .run()
        }.flatMap {
            return Model.shared.didRestore(model, on: self)
        }
    }
}
