public struct Parent<Value>: Property
    where Value: Model
{
    public var type: Any.Type {
        return Value.ID.self
    }

    public let name: String
    public let dataType: DatabaseSchema.DataType?
    public var constraints: [DatabaseSchema.FieldConstraint]
    
    public init(
        _ name: String,
        dataType: DatabaseSchema.DataType? = nil,
        constraints: DatabaseSchema.FieldConstraint...
    ) {
        self.name = name
        self.dataType = dataType
        self.constraints = constraints
    }

    func cached(from output: DatabaseOutput) throws -> Any? {
        guard output.contains(field: self.name) else {
            return nil
        }
        return try output.decode(field: self.name, as: Value.ID.self)
    }
    
    func encode(to encoder: inout ModelEncoder, from storage: Storage) throws {
        if let cache = storage.eagerLoads[Value.entity] {
            let parent = try cache.get(id: storage.get(self.name, as: Value.ID.self))
                .map { $0 as! Row<Value> }
                .first!
            try encoder.encode(parent, forKey: "\(Value.self)".lowercased())
        } else {
            try encoder.encode(storage.get(self.name, as: Value.ID.self), forKey: self.name)
        }
    }
    
    func decode(from decoder: ModelDecoder, to storage: inout Storage) throws {
        try storage.set(self.name, to: decoder.decode(Value.ID.self, forKey: self.name))
    }
}
