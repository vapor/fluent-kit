public struct Children<Value>: AnyProperty
    where Value: Model
{
    public let name: String
    
    public init(_ name: String) {
        self.name = name
    }
    
    func encode(to encoder: inout ModelEncoder, from storage: Storage) throws {
        if let cache = storage.eagerLoads[Value.entity] {
            #warning("TODO: use correct root id")
            let children = try cache.get(id: storage.get("id", as: Value.ID.self))
                .map { $0 as! Row<Value> }
            try encoder.encode(children, forKey: "\(Value.self)".lowercased() + "s")
        }
    }
    
    func decode(from decoder: ModelDecoder, to storage: inout Storage) throws {
        // don't decode
    }
}
