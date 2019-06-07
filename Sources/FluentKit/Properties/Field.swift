@propertyWrapper
public final class Field<Value>: AnyField
    where Value: Codable
{
    public var type: Any.Type {
        return Value.self
    }

    var nameOverride: String?
    var input: DatabaseQuery.Value?
    var output: Value?
    var label: String?
    
    var name: String {
        guard let name = self.nameOverride ?? self.label else {
            fatalError("Label not set")
        }
        return name
    }

    var storage: Storage?
    var dataType: DatabaseSchema.DataType?
    var constraints: [DatabaseSchema.FieldConstraint]
    var reflectionContext: ReflectionContext?
    
    public init(_ nameOverride: String) {
        self.nameOverride = nameOverride
        self.constraints = []
    }

    public init() {
        self.constraints = []
    }

    public var value: Value {
        get {
            if let context = self.reflectionContext {
                context.lastAccessedField = self
                return ((Value.self as! AnyReflectable.Type).anyReflectionValue as! Value)
            } else {
                if let input = self.input {
                    switch input {
                    case .bind(let encodable):
                        return encodable as! Value
                    default:
                        fatalError("Unsupported input type")
                    }
                } else if let output = self.output {
                    return output
                } else {
                    fatalError("\(self.name) was not selected.")
                }
            }
        }
        set {
            self.input = .bind(newValue)
        }
    }


    func encode(to encoder: inout ModelEncoder) throws {
        try encoder.encode(self.value, forKey: self.name)
    }

    func decode(from decoder: ModelDecoder) throws {
        self.input = try .bind(decoder.decode(Value.self, forKey: self.name))
    }
    
    func initialize(label: String) {
        self.label = label
    }
    
    func initialize(reflectionContext: ReflectionContext) {
        self.reflectionContext = reflectionContext
    }
    
    func initialize(storage: Storage) throws {
        guard let output = self.storage?.output else {
            return
        }
        guard output.contains(field: self.name) else {
            return
        }
        self.output = try output.decode(field: self.name, as: Value.self)
    }

//    func cached(from output: DatabaseOutput) throws -> Any? {
//        guard output.contains(field: self.name) else {
//            return nil
//        }
//        return try output.decode(field: self.name, as: Value.self)
//    }
//
//    func encode(to encoder: inout ModelEncoder, from row: AnyRow) throws {
//        try encoder.encode(row.storage.get(self.name, as: Value.self), forKey: self.name)
//    }
//
//    func decode(from decoder: ModelDecoder, to row: AnyRow) throws {
//        try row.storage.set(self.name, to: decoder.decode(Value.self, forKey: self.name))
//    }
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
