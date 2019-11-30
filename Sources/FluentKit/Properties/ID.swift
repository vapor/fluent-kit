public protocol RandomGeneratable {
    static func generateRandom() -> Self
}

extension UUID: RandomGeneratable {
    public static func generateRandom() -> UUID {
        return .init()
    }
}

@propertyWrapper
public final class ID<Value>: AnyID, FieldRepresentable
    where Value: Codable
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

    public let field: Field<Value?>
    public var exists: Bool
    let generator: Generator
    var cachedOutput: DatabaseOutput?

    public var key: String {
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

    public var projectedValue: ID<Value> {
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

    public init(key: String, generatedBy generator: Generator? = nil) {
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
            let generatable = Value.self as! (RandomGeneratable & Encodable).Type
            self.inputValue = .bind(generatable.generateRandom())
        case .user:
            // do nothing
            break
        }
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
