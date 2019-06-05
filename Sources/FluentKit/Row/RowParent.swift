public struct RowParent<Value>
    where Value: Model
{
    var storage: Storage
    let field: String

    public var id: Value.ID {
        get {
            return self.storage.get(self.field)
        }
        set {
            self.storage.set(self.field, to: newValue)
        }
    }

    public func eagerLoaded() throws -> Row<Value> {
        guard let cache = self.storage.eagerLoads[Value.entity] else {
            throw FluentError.missingEagerLoad(name: Value.entity.self)
        }
        return try cache.get(id: self.storage.get(self.field, as: Value.ID.self))
            .map { $0 as! Row<Value> }
            .first!
    }

    public func query(on database: Database) -> QueryBuilder<Value> {
        return Value.query(on: database)
            .filter(self.field, .equal, self.storage.get(self.field, as: Value.ID.self))
    }


    public func get(on database: Database) -> EventLoopFuture<Row<Value>> {
        return self.query(on: database).first().map { parent in
            guard let parent = parent else {
                fatalError()
            }
            return parent
        }
    }
}
