#warning("TODO: children")

public struct Children<Value>: RelationType where Value: Model {
    public init() { }


    public func eagerLoaded() throws -> [Value] {
        #warning("TODO: fixme")
        return []
//        guard let rows = try self.children.eagerLoaded(for: self.row) else {
//            throw FluentError.missingEagerLoad(name: Value.entity.self)
//        }
//        return rows
    }

    public func query(on database: Database) -> QueryBuilder<Value> {
        #warning("TODO: fixme")
        return Value.query(on: database)
//        let id = self.row.storage.get(self.children.name, as: Value.ID.self)
//        return Value.query(on: database)
//            .filter(self.children.name, .equal, id)
    }
}

//public struct Children<Value>: AnyProperty
//    where Value: Model
//{
//    public let name: String
//
//    public init(_ name: String) {
//        self.name = name
//    }
//
//    func eagerLoaded(for row: AnyRow) throws -> [Row<Value>]? {
//        guard let cache = row.storage.eagerLoads[Value.entity] else {
//            return nil
//        }
//        return try cache.get(id: row.storage.get(row.model.id, as: Value.ID.self))
//            .map { $0 as! Row<Value> }
//    }
//
//    func encode(to encoder: inout ModelEncoder, from row: AnyRow) throws {
//        if let rows = try self.eagerLoaded(for: row) {
//            try encoder.encode(rows, forKey: Value.entity)
//        }
//    }
//
//    func decode(from decoder: ModelDecoder, to row: AnyRow) throws {
//        // don't decode
//    }
//}
