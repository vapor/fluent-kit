public struct Children<Value>: AnyProperty
    where Value: Model
{
    public let name: String
    
    public init(_ name: String) {
        self.name = name
    }

    func eagerLoaded(for row: AnyRow) throws -> [Row<Value>]? {
        guard let cache = row.storage.eagerLoads[Value.entity] else {
            return nil
        }
        return try cache.get(id: row.storage.get(row.model.id, as: Value.ID.self))
            .map { $0 as! Row<Value> }
    }
    
    func encode(to encoder: inout ModelEncoder, from row: AnyRow) throws {
        if let rows = try self.eagerLoaded(for: row) {
            #warning("TODO: better plural support")
            try encoder.encode(rows, forKey: "\(Value.self)".lowercased() + "s")
        }
    }
    
    func decode(from decoder: ModelDecoder, to row: AnyRow) throws {
        // don't decode
    }
}
