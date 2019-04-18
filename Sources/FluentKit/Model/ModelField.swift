public enum ModelError: Error {
    case missingField(name: String)
}

#warning("TODO: fixme, value type")
public final class ModelField<Model, Value>: ModelProperty
    where Model: FluentKit.Model, Value: Codable
{
    public var type: Any.Type {
        return Value.self
    }

    public var name: String

    public var input: Encodable? {
        switch self.storage {
        case .input(let value):
            return value
        default:
            return nil
        }
    }

    public var dataType: DatabaseSchema.DataType?

    public var constraints: [DatabaseSchema.FieldConstraint]?

    public func load(from storage: ModelStorage) throws {
        guard let output = storage.output else {
            fatalError("No model storage output")
        }
        if output.contains(field: self.name) {
            self.storage = try .output(output.decode(field: self.name, as: Value.self))
        } else {
            self.storage = .none
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
                fatalError("No value was selected for \(Model.self).\(self.name) (\(Value.self))")
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
    
    public init(
        _ name: String,
        dataType: DatabaseSchema.DataType? = nil,
        constraints: [DatabaseSchema.FieldConstraint]? = nil
    ) {
        self.name = name
        self.dataType = dataType
        self.constraints = constraints
        self.storage = .none
    }
    
    public func encode(to encoder: inout ModelEncoder) throws {
        switch self.storage {
        case .input(let input):
            try encoder.encode(input, forKey: self.name)
        case .output(let output):
            try encoder.encode(output, forKey: self.name)
        case .none:
            break
        }
    }

    public func decode(from decoder: ModelDecoder) throws {
        self.storage = try .input(decoder.decode(Value.self, forKey: self.name))
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
