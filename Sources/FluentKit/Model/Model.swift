public protocol Model: AnyModel, CustomStringConvertible {
    associatedtype ID: ModelID
    var id: Field<ID> { get }
}

extension Model {
    public func save(on database: Database) -> EventLoopFuture<Void> {
        if self.exists {
            return self.update(on: database)
        } else {
            return self.create(on: database)
        }
    }
    
    public func create(on database: Database) -> EventLoopFuture<Void> {
        precondition(!self.exists)
        let builder = database.query(Self.self).set(self.storage.input)
        builder.query.action = .create
        return builder.run { model in
            #warning("for mysql, we might need to hold onto storage input")
            self.storage = DefaultModelStorage(
                output: model.storage.output,
                eagerLoads: model.storage.eagerLoads,
                exists: true
            )
        }
    }
    
    public func update(on database: Database) -> EventLoopFuture<Void> {
        precondition(self.exists)
        let builder = try! database.query(Self.self).filter(\.id == self.id.get()).set(self.storage.input)
        builder.query.action = .update
        return builder.run { model in
            self.storage = DefaultModelStorage(
                output: model.storage.output,
                eagerLoads: model.storage.eagerLoads,
                exists: true
            )
            #warning("for mysql, we might need to hold onto storage input")
        }
    }
    
    public func delete(on database: Database) -> EventLoopFuture<Void> {
        precondition(self.exists)
        let builder = try! database.query(Self.self).filter(\.id == self.id.get())
        builder.query.action = .delete
        return builder.run().map {
            self.storage.exists = false
        }
    }
}



extension Array where Element: Model {
    public func create(on database: Database) -> EventLoopFuture<Void> {
        let builder = database.query(Element.self)
        for model in self {
            precondition(!model.exists)
            builder.set(model.storage.input)
        }
        builder.query.action = .create
        var it = self.makeIterator()
        return builder.run { model in
            let next = it.next()!
            next.storage = DefaultModelStorage(
                output: model.storage.output,
                eagerLoads: model.storage.eagerLoads,
                exists: true
            )
        }
    }
}
