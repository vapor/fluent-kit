extension Model {
    public typealias ID<Value> = IDProperty<Self, Value>
        where Value: Codable
}

// MARK: Type

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
            return self.value
        }
        set {
            self.value = newValue
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
        // Check if current value is nil.
        switch self.inputValue {
        case .none, .null:
            break
        case .bind(let value) where value.isNil:
            break
        default:
            return
        }

        // If nil, generate a value.
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
}

extension IDProperty: CustomStringConvertible {
    public var description: String {
        "@\(Model.self).ID<\(Value.self)>(key: \(self.key))"
    }
}

// MARK: Property

extension IDProperty: AnyProperty { }

extension IDProperty: Property {
    public var value: Value? {
        get {
            return self.field.value ?? nil
        }
        set {
            self.field.value = newValue
        }
    }
}

// MARK: Queryable

extension IDProperty: AnyQueryableProperty {
    public var path: [FieldKey] {
        self.field.path
    }
}

extension IDProperty: QueryableProperty { }

// MARK: Database

extension IDProperty: AnyDatabaseProperty {
    public var keys: [FieldKey] {
        self.field.keys
    }

    public func input(to input: DatabaseInput) {
        self.field.input(to: input)
    }

    public func output(from output: DatabaseOutput) throws {
        self.exists = true
        self.cachedOutput = output
        try self.field.output(from: output)
    }
}

// MARK: Codable

extension IDProperty: AnyCodableProperty {
    public func encode(to encoder: Encoder) throws {
        try self.field.encode(to: encoder)
    }

    public func decode(from decoder: Decoder) throws {
        try self.field.decode(from: decoder)
    }
}

// MARK: ID

extension IDProperty: AnyID { }

protocol AnyID {
    func generate()
    var exists: Bool { get set }
    var cachedOutput: DatabaseOutput? { get set }
}


private extension Encodable {
    var isNil: Bool {
        if let optional = self as? AnyOptionalType {
            return optional.wrappedValue == nil
        } else {
            return false
        }
    }
}
