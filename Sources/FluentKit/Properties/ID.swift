public protocol RandomGeneratable {
    static func generateRandom() -> Self
}

extension UUID: RandomGeneratable {
    public static func generateRandom() -> UUID {
        return .init()
    }
}

@propertyWrapper
public final class ID<Value>: AnyID, Filterable
    where Value: Codable
{
    public enum Generator {
        case automatic
        case user
        case random
        case database
    }

    let field: Field<Value?>
    let generator: Generator
    var exists: Bool
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

    public init(key: String, generatedBy generator: Generator = .automatic) {
        self.field = .init(key: key)
        self.generator = generator
        self.exists = false
        self.cachedOutput = nil
    }

    func generate() {
        switch self.generator {
        case .automatic:
            if let generatable = Value.self as? (RandomGeneratable & Encodable).Type {
                self.inputValue = .bind(generatable.generateRandom())
            } else if Value.self is Int.Type {
                self.inputValue = .default
            } else {
                // do nothing
            }
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
