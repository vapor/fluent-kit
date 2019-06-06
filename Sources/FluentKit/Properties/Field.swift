@propertyWrapper
public final class Field<Value>: AnyField
    where Value: Codable & Reflectable
{
    public var type: Any.Type {
        return Value.self
    }

    var name: String?
    var input: DatabaseQuery.Value?

    var storage: Storage?
    let dataType: DatabaseSchema.DataType?
    var constraints: [DatabaseSchema.FieldConstraint]
    var reflectionContext: ReflectionContext?

    public init() {
        self.name = nil
        self.dataType = nil
        self.constraints = []
    }

    public var value: Value {
        get {
            if let context = self.reflectionContext {
                context.lastAccessedField = self
                return Value.reflectionValue
            } else {
                if let input = self.input {
                    switch input {
                    case .bind(let encodable):
                        return encodable as! Value
                    default:
                        fatalError("Unsupported input type")
                    }
                } else {
                    return try! self.storage!.output!.decode(field: self.name!, as: Value.self)
                }
            }
        }
        set {
            self.input = .bind(newValue)
        }
    }


    func encode(to encoder: inout ModelEncoder) throws {
        try encoder.encode(self.value, forKey: self.name!)
    }

    func decode(from decoder: ModelDecoder) throws {
        self.input = try .bind(decoder.decode(Value.self, forKey: self.name!))
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
