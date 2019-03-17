public enum ModelError: Error {
    case missingField(name: String)
}

public struct ModelField<Model, Value>: ModelProperty
    where Model: FluentKit.Model, Value: Codable
{
    public var type: Any.Type {
        return Value.self
    }
    
    public var constraints: [DatabaseSchema.FieldConstraint]
    
    public let name: String
    
//    public var path: [String] {
//        return self.model.storage.path + [self.name]
//    }

    public let dataType: DatabaseSchema.DataType?
    
    struct Interface: Codable {
        let name: String
    }
    
    public init(
        _ name: String,
        dataType: DatabaseSchema.DataType? = nil,
        constraints: DatabaseSchema.FieldConstraint...
    ) {
        self.name = name
        self.dataType = dataType
        self.constraints = constraints
    }
    
    public func encode(to encoder: inout ModelEncoder, from storage: ModelStorage) throws {
        try encoder.encode(storage.get(self.name, as: Value.self), forKey: self.name)
    }

    public func decode(from decoder: ModelDecoder, to storage: inout ModelStorage) throws {
        try storage.set(self.name, to: decoder.decode(Value.self, forKey: self.name))
    }
}

//extension Model {
//    public func field<Value>(
//        _ name: String,
//        _ dataType: DatabaseSchema.DataType? = nil,
//        _ constraints: DatabaseSchema.FieldConstraint...
//    ) -> Field<Value>
//        where Value: Codable
//    {
//        return .init(name: name, dataType: dataType, constraints: constraints)
//    }
//
//    public func id<Value>(
//        _ name: String,
//        _ dataType: DatabaseSchema.DataType? = nil,
//        _ constraints: DatabaseSchema.FieldConstraint...
//    ) -> Field<Value>
//        where Value: Codable
//    {
//        return .init(
//            model: self,
//            name: name,
//            dataType: dataType,
//            constraints: constraints + [.identifier]
//        )
//    }
//}
