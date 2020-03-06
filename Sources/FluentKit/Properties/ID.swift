extension Model {
    public typealias ID<Value> = IDProperty<Self, Value>
        where Value: Codable
}

@propertyWrapper
public final class IDProperty<Model, Value>
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

    public let field: Model.OptionalField<Value>
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

    public var projectedValue: IDProperty<Model, Value> {
        return self
    }
    
    public var wrappedValue: Value? {
        get {
            return self.field.value
        }
        set {
            self.field.value = newValue
        }
    }

    public convenience init(key: FieldKey = .id) {
        guard Value.self is UUID.Type else {
            // Ensure the default @ID type is using UUID which
            // is the only identifier type supported by all drivers.
            fatalError("@ID requires UUID, use @ID(custom:) for \(Value.self).")
        }
        guard key == .id else {
            // Ensure the default @ID is using the special .id key
            // which is the only identifier key supported by all drivers.
            //
            // Additional identifying fields can be added using @Field
            // with a unique constraint.
            fatalError("@ID requires .id key, use @ID(custom:) for key '\(key)'.")
        }
        self.init(custom: .id, generatedBy: .random)
    }

    public init(custom key: FieldKey, generatedBy generator: Generator? = nil) {
        self.field = .init(key: key)
        self.generator = generator ?? .default(for: Value.self)
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

extension IDProperty: PropertyProtocol {
    public var value: Value? {
        get {
            return self.field.value
        }
        set {
            self.field.value = newValue
        }
    }
}

extension IDProperty: FieldProtocol { }

extension IDProperty: AnyField { }

extension IDProperty: AnyProperty {
    public var nested: [AnyProperty] {
        []
    }
    public var path: [FieldKey] {
        self.field.path
    }

    public func input(to input: inout DatabaseInput) {
        self.field.input(to: &input)
    }

    public func output(from output: DatabaseOutput) throws {
        self.exists = true
        self.cachedOutput = output
        try self.field.output(from: output)
    }

    public func encode(to encoder: Encoder) throws {
        try self.field.encode(to: encoder)
    }

    public func decode(from decoder: Decoder) throws {
        try self.field.decode(from: decoder)
    }
}

extension IDProperty: AnyID { }

protocol AnyID {
    func generate()
    var exists: Bool { get set }
    var cachedOutput: DatabaseOutput? { get set }
}
