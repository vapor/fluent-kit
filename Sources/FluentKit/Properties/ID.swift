import Foundation

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

    /// Initializes an `ID` property with the key `.id` and type `UUID`.
    ///
    /// Use the `.init(custom:generatedBy:)` initializer to specify a custom ID key or type.
    public convenience init() where Value == UUID {
        self.init(custom: .id, generatedBy: .random)
    }
    
    /// Helper type for compatibility initializer syntax. Do not use this type directly.
    public enum _DefaultIDFieldKey: ExpressibleByStringLiteral {
        case id
        
        @available(*, deprecated, message: "The `@ID(key: \"id\")` syntax is deprecated. Use `@ID` or `@ID()` instead.")
        public init(stringLiteral value: String) {
            guard value == "id" else {
                fatalError("@ID() may not specify a key; use @ID(custom:) for '\(value)'.")
            }
            self = .id
        }
    }
    
    /// Compatibility syntax for initializing an `ID` property.
    ///
    /// This syntax is no longer recommended; use `@ID` instead.
    public convenience init(key _: _DefaultIDFieldKey) where Value == UUID {
        self.init()
    }

    /// Create an `ID` property with a specific key, value type, and optional value generator.
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
        case .bind(let value) where (value as? AnyOptionalType).map({ $0.wrappedValue == nil }) ?? false:
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

// MARK: Query-addressable

extension IDProperty: AnyQueryAddressableProperty {
    public var anyQueryableProperty: AnyQueryableProperty { self }
    public var queryablePath: [FieldKey] { self.path }
}

extension IDProperty: QueryAddressableProperty {
    public var queryableProperty: IDProperty<Model, Value> { self }
}

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

protocol AnyID: AnyObject {
    func generate()
    var exists: Bool { get set }
    var cachedOutput: DatabaseOutput? { get set }
}
