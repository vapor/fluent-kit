#warning("TODO: children")

extension Model {
    public typealias Children<ChildType> = ModelChildren<Self, ChildType>
        where ChildType: Model
}

public struct ModelChildren<ParentType, ChildType>: RelationType
    where ParentType: Model, ChildType: Model
{
    var nameOverride: String?
    
    var foreignIDName: String {
        return self.nameOverride ?? ParentType.name + "ID"
    }
    
    var baseIDName: String {
        return ParentType.name(for: \.id)
    }
    
    public init(nameOverride: String?) {
        self.nameOverride = nameOverride
    }


    public func eagerLoaded() throws -> [ChildType] {
        #warning("TODO: fixme")
        return []
//        guard let rows = try self.children.eagerLoaded(for: self.row) else {
//            throw FluentError.missingEagerLoad(name: Value.entity.self)
//        }
//        return rows
    }

    public func query(on database: Database) -> QueryBuilder<ChildType> {
        #warning("TODO: fixme")
        return ChildType.query(on: database)
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
