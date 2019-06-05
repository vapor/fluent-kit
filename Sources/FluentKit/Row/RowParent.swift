public struct RowParent<Child, Parent>
    where Parent: Model, Child: Model
{
    let row: Row<Child>
    let key: Child.ParentKey<Parent>

    public var id: Parent.ID {
        get {
            return self.row.get(Child.parent(forKey: key).id.name)
        }
        nonmutating set {
            self.row.set(Child.parent(forKey: key).id.name, to: newValue)
        }
    }

    public func eagerLoaded() -> Row<Parent> {
        guard let cache = self.row.storage.eagerLoads[Parent.entity] else {
            fatalError("No cache set on storage.")
        }
        return try! cache.get(id: row.get(Child.parent(forKey: key).id.name, as: Parent.ID.self))
            .map { $0 as! Row<Parent> }
            .first!
    }

    public func query(on database: Database) -> QueryBuilder<Parent> {
        let parent = Child.parent(forKey: self.key)
        return Parent.query(on: database)
            .filter(Parent.shared.id.name, .equal, self.row.get(parent.id.name, as: Parent.ID.self))
    }


    public func get(on database: Database) -> EventLoopFuture<Row<Parent>> {
        return self.query(on: database).first().map { parent in
            guard let parent = parent else {
                fatalError()
            }
            return parent
        }
    }
}
