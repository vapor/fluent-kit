public enum ModelError: Error {
    case missingField(name: String)
}

public struct ModelField<Entity, Value>: ModelProperty
    where Entity: FluentKit.AnyModel, Value: Codable
{
    public var type: Any.Type {
        return Value.self
    }
    
    public var constraints: [DatabaseSchema.FieldConstraint]
    
    public let name: String
    
    public var path: [String] {
        return self.model.storage.path + [self.name]
    }

    public let dataType: DatabaseSchema.DataType?
    
    internal let model: Entity
    
    struct Interface: Codable {
        let name: String
    }
    
    init(model: Entity, name: String, dataType: DatabaseSchema.DataType?, constraints: [DatabaseSchema.FieldConstraint]) {
        self.model = model
        self.name = name
        self.dataType = dataType
        self.constraints = constraints
    }
    
    public func get() throws -> Value {
        if let input = self.model.storage.input[self.name] {
            switch input {
            case .bind(let encodable): return encodable as! Value
            default: fatalError("Non-matching input.")
            }
        } else if let output = self.model.storage.output {
            return try output.decode(field: self.name, as: Value.self)
        } else {
            throw ModelError.missingField(name: "\(Entity.self).\(self.name)")
        }
    }
    
    public func set(to value: Value) {
        self.model.storage.input[self.name] = .bind(value)
    }
    
    #warning("TODO: better name")
    public func mut(_ closure: (inout Value) throws -> ()) throws {
        var value: Value = try self.get()
        try closure(&value)
        self.set(to: value)
    }
    
    public func encode(to encoder: inout ModelEncoder) throws {
        try encoder.encode(self.get(), forKey: self.name)
    }
    
    public func decode(from decoder: ModelDecoder) throws {
        try self.set(to: decoder.decode(Value.self, forKey: self.name))
    }
}

extension AnyModel {
    public typealias Field<Value> = ModelField<Self, Value>
        where Value: Codable
    
    public func field<Value>(
        _ name: String,
        _ dataType: DatabaseSchema.DataType? = nil,
        _ constraints: DatabaseSchema.FieldConstraint...
    ) -> Field<Value>
        where Value: Codable
    {
        return .init(model: self, name: name, dataType: dataType, constraints: constraints)
    }
    
    public func id<Value>(
        _ name: String,
        _ dataType: DatabaseSchema.DataType? = nil,
        _ constraints: DatabaseSchema.FieldConstraint...
    ) -> Field<Value>
        where Value: Codable
    {
        return .init(
            model: self,
            name: name,
            dataType: dataType,
            constraints: constraints + [.identifier]
        )
    }
}
