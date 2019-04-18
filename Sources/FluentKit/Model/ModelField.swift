public enum ModelError: Error {
    case missingField(name: String)
}

public struct ModelField<Model, Value>: ModelProperty
    where Model: FluentKit.Model, Value: Codable
{
    public var type: Any.Type {
        return Value.self
    }

    public var input: Encodable? {
        switch self.storage {
        case .input(let value):
            return value
        default:
            return nil
        }
    }

    internal enum Storage {
        case none
        case output(Value)
        case input(Value)
    }

    internal var storage: Storage

    public var value: Value {
        get {
            switch self.storage {
            case .none:
                fatalError("No value was selected: \(Value.self)")
            case .output(let output):
                return output
            case .input(let input):
                return input
            }
        }
        set {
            self.storage = .input(newValue)
        }
    }
    
    public init() {
        self.storage = .none
    }

    public init(value: Value) {
        self.storage = .input(value)
    }
    
    public func encode(to encoder: inout ModelEncoder, from storage: ModelStorage) throws {
        #warning("FIXME")
        try encoder.encode(storage.get("foo", as: Value.self), forKey: "foo")
    }

    public func decode(from decoder: ModelDecoder, to storage: inout ModelStorage) throws {
        #warning("FIXME")
        try storage.set("foo", to: decoder.decode(Value.self, forKey: "foo"))
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
