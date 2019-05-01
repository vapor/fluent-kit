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

    internal let dataType: DatabaseSchema.DataType?

    #warning("TODO: auto migrate")
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

    func cached(from output: DatabaseOutput) throws -> Any? {
        guard output.contains(field: self.name) else {
            return nil
        }
        return try output.decode(field: self.name, as: Value.self)
    }
    
    func encode(to encoder: inout ModelEncoder, from storage: ModelStorage) throws {
        try encoder.encode(storage.get(self.name, as: Value.self), forKey: self.name)
    }

    func decode(from decoder: ModelDecoder, to storage: inout ModelStorage) throws {
        try storage.set(self.name, to: decoder.decode(Value.self, forKey: self.name))
    }
}

extension ModelField: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self.init(value)
    }
}


extension ModelRow {
    public subscript<Value>(_ field: Model.FieldKey<Value>) -> Value
        where Value: Codable
    {
        get {
            return self.get(field)
        }
        set {
            return self.set(field, to: newValue)
        }
    }

    public func has<Value>(_ field: Model.FieldKey<Value>) -> Bool
        where Value: Codable
    {
        return self.storage.cachedOutput[Model.field(forKey: field).name] != nil
    }

    func get<Value>(_ key: Model.FieldKey<Value>) -> Value
        where Value: Codable
    {
        return self.get(Model.field(forKey: key))
    }

    func get<Value>(_ field: Model.Field<Value>) -> Value
        where Value: Codable
    {
        return self.storage.get(field.name)
    }

    func set<Value>(_ key: Model.FieldKey<Value>, to value: Value)
        where Value: Codable
    {
        self.set(Model.field(forKey: key), to: value)
    }

    func set<Value>(_ field: Model.Field<Value>, to value: Value)
        where Value: Codable
    {
        self.storage.set(field.name, to: value)
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
