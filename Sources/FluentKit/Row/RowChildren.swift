public struct RowChildren<Value>
    where Value: Model
{
    let parentID: String
    let childID: String
    let storage: Storage

    public func eagerLoaded() throws -> [Row<Value>] {
        guard let cache = self.storage.eagerLoads[Value.entity] else {
            throw FluentError.missingEagerLoad(name: Value.entity.self)
        }
        return try cache.get(id: self.storage.get(self.parentID, as: Value.ID.self))
            .map { $0 as! Row<Value> }
    }


    public func query(on database: Database) -> QueryBuilder<Value> {
        return Value.query(on: database)
            .filter(self.childID, .equal, self.storage.get(self.parentID, as: Value.ID.self))
    }
}
