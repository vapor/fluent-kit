public protocol RandomGeneratable {
    static func generateRandom() -> Self
}

extension UUID: RandomGeneratable {
    public static func generateRandom() -> UUID {
        return .init()
    }
}

extension Model {
    public typealias ID<Value> = ModelID<Self, Value>
        where Value: Codable
}

public indirect enum FieldKey: Equatable, Hashable, ExpressibleByStringLiteral, CustomStringConvertible {
    case id
    case string(String)
    case prefixed(String, FieldKey)
    case aggregate

    public var description: String {
        switch self {
        case .id:
            return "id"
        case .string(let name):
            return name
        case .aggregate:
            return "aggregate"
        case .prefixed(let prefix, let key):
            return prefix + key.description
        }
    }

    public init(stringLiteral value: String) {
        switch value {
        case "id", "_id":
            self = .id
        default:
            self = .string(value)
        }
    }
}

@propertyWrapper
public final class ModelID<Model, Value>
    where Model: FluentKit.Model, Value: Codable
{
    public enum Generator {
        case user
        case random
        case database

        static func `default`<T>(for type: T.Type) -> Generator {
            if T.self is RandomGeneratable.Type {
                return .random
            } else if T.self == Int.self {
                return .database
            } else {
                return .user
            }
        }
    }

    public let field: Model.Field<Value?>
    public var exists: Bool
    let generator: Generator
    var cachedOutput: DatabaseOutput?

    public var key: FieldKey {
        return self.field.key
    }

    var inputValue: DatabaseQuery.Value? {
        get {
            return self.field.inputValue
        }
        set {
            self.field.inputValue = newValue
        }
    }

    public var projectedValue: ModelID<Model, Value> {
        return self
    }
    
    public var wrappedValue: Value? {
        get {
            return self.field.wrappedValue
        }
        set {
            self.field.wrappedValue = newValue
        }
    }

    public init(key: FieldKey, generatedBy generator: Generator? = nil) {
        // Ensure that @ID is using the special .id key.
        // Additional identifying fields can be added using @Field
        // with a unique constraint.
        assert(key == .id, "@ID key must be .id.")
        self.field = .init(key: key)
        self.generator = generator ?? Generator.default(for: Value.self)
        self.exists = false
        self.cachedOutput = nil
    }

    func generate() {
        switch self.generator {
        case .database:
            self.inputValue = .default
        case .random:
            // only generate an id if none is set
            let generate: Bool

            // check to see if an id has been set
            switch inputValue {
            case .some(let value):
                switch value {
                case .bind(let value):
                    generate = (value as? Value) == nil
                default:
                    generate = true
                }
            case .none:
                generate = true
            }

            // if no id set, generate the value
            if generate {
                let generatable = Value.self as! (RandomGeneratable & Encodable).Type
                self.inputValue = .bind(generatable.generateRandom())
            }
        case .user:
            // do nothing
            break
        }
    }
}

extension ModelID: AnyProperty {
    var keys: [FieldKey] {
        self.field.keys
    }

    func input(to input: inout DatabaseInput) {
        self.field.input(to: &input)
    }

    func output(from output: DatabaseOutput) throws {
        self.exists = true
        self.cachedOutput = output
        try self.field.output(from: output)
    }

    func encode(to encoder: Encoder) throws {
        try self.field.encode(to: encoder)
    }

    func decode(from decoder: Decoder) throws {
        try self.field.decode(from: decoder)
    }
}

extension ModelID: FieldRepresentable { }
extension ModelID: AnyID { }

protocol AnyID: AnyProperty {
    func generate()
    var exists: Bool { get set }
    var cachedOutput: DatabaseOutput? { get set }
}
