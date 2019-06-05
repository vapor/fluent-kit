public struct RowChildren<Value>
    where Value: Model
{
    let children: Children<Value>
    let row: AnyRow

    public func eagerLoaded() throws -> [Row<Value>] {
        guard let rows = try self.children.eagerLoaded(for: self.row) else {
            throw FluentError.missingEagerLoad(name: Value.entity.self)
        }
        return rows
    }

    public func query(on database: Database) -> QueryBuilder<Value> {
        let id = self.row.storage.get(self.children.name, as: Value.ID.self)
        return Value.query(on: database)
            .filter(self.children.name, .equal, id)
    }
}
