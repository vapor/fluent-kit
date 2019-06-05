public struct RowParent<Value>
    where Value: Model
{
    let parent: Parent<Value>
    let row: AnyRow

    public var id: Value.ID {
        get {
            return self.row.storage.get(self.parent.name)
        }
        nonmutating set {
            self.row.storage.set(self.parent.name, to: newValue)
        }
    }

    public func eagerLoaded() throws -> Row<Value> {
        guard let row = try self.parent.eagerLoaded(for: self.row) else {
            throw FluentError.missingEagerLoad(name: Value.entity.self)
        }
        return row
    }

    public func query(on database: Database) -> QueryBuilder<Value> {
        let id = self.row.storage.get(self.parent.name, as: Value.ID.self)
        return Value.query(on: database)
            .filter(self.parent.name, .equal, id)
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
