public struct Field<Value>: AnyField
    where Value: Codable
{
    public var type: Any.Type {
        return Value.self
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
        return try output.decode(field: self.name, as: Value.self)
    }
    
    func encode(to encoder: inout ModelEncoder, from row: AnyRow) throws {
        try encoder.encode(row.storage.get(self.name, as: Value.self), forKey: self.name)
    }

    func decode(from decoder: ModelDecoder, to row: AnyRow) throws {
        try row.storage.set(self.name, to: decoder.decode(Value.self, forKey: self.name))
    }
}

extension Field: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self.init(value)
    }
}
