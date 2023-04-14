extension Fields {
    public typealias OptionalBoolean<Format> = OptionalBooleanProperty<Self, Format>
        where Format: BooleanPropertyFormat
}

/// A Fluent model property which represents an optional boolean (true/false) value.
///
/// By default, `Bool` properties are stored in a database using the storage format
/// defined by the database driver, which corresponds to using the `.bool` data type
/// on the appropriate field in a migration. This property wrapper allows specifying
/// an alternative storage format - such the strings "true" and "false" - which is
/// automatically translated to and from a Swift `Bool` when loading and saving the
/// owning model. This is expected to be most useful when working with existing
/// database schemas.
///
/// Example:
///
///     final class MyModel: Model {
///         let schema = "my_models"
///
///         @ID(key: .id) var id: UUID?
///
///         // When not `nil`, this field will be stored using the database's native boolean format.
///         @OptionalField(key: "rawEnabled") var rawEnabled: Bool?
///
///         // When not `nil`, this field will be stored as a string, either "true" or "false".
///         @OptionalBoolean(key: "enabled", format: .trueFalse) var enabled: Bool?
///
///         init() {}
///     }
///
///     struct MyModelMigration: AsyncMigration {
///         func prepare(on database: Database) async throws -> Void {
///             try await database.schema(MyModel.schema)
///                 .id()
///                 .field("rawEnabled", .bool)
///                 .field("enabled", .string)
///                 .create()
///         }
///
///         func revert(on database: Database) async throws -> Void { try await database.schema(MyModel.schema).delete() }
///     }
///
/// - Note: See also ``BooleanProperty`` and ``BooleanPropertyFormat``.
@propertyWrapper
public final class OptionalBooleanProperty<Model, Format>
    where Model: FluentKit.Fields, Format: BooleanPropertyFormat
{
    @OptionalFieldProperty<Model, Format.Value>
    public var field: Format.Value?
    public let format: Format

    public var projectedValue: OptionalBooleanProperty<Model, Format> { self }

    public var wrappedValue: Bool? {
        get {
            switch self.value {
            case .none, .some(.none): return nil
            case .some(.some(let value)): return value
            }
        }
        set { self.value = .some(newValue) }
    }

    public init(key: FieldKey, format: Format) {
        self._field = .init(key: key)
        self.format = format
    }
}

extension OptionalBooleanProperty where Format == DefaultBooleanPropertyFormat {
    public convenience init(key: FieldKey) {
        self.init(key: key, format: .default)
    }
}

/// This is a workaround for Swift 5.4's inability to correctly infer the format type
/// using the `Self` constraints on the various static properties.
extension OptionalBooleanProperty {
    public convenience init(key: FieldKey, format factory: BooleanPropertyFormatFactory<Format>) {
        self.init(key: key, format: factory.format)
    }
}

extension OptionalBooleanProperty: AnyProperty {}

extension OptionalBooleanProperty: Property {
    public var value: Bool?? {
        get {
            switch self.$field.value {
            case .some(.some(let value)): return .some(self.format.parse(value))
            case .some(.none): return .some(.none)
            case .none: return .none
            }
        }
        set {
            switch newValue {
            case .some(.some(let newValue)): self.$field.value = .some(.some(self.format.serialize(newValue)))
            case .some(.none): self.$field.value = .some(.none)
            case .none: self.$field.value = .none
            }
        }
    }
}

extension OptionalBooleanProperty: AnyQueryableProperty {
    public var path: [FieldKey] { self.$field.path }
}

extension OptionalBooleanProperty: QueryableProperty {
    public static func queryValue(_ value: Bool?) -> DatabaseQuery.Value {
        value.map { .bind(Format.init().serialize($0)) } ?? .null
    }
}

extension OptionalBooleanProperty: AnyQueryAddressableProperty {
    public var anyQueryableProperty: AnyQueryableProperty { self }
    public var queryablePath: [FieldKey] { self.path }
}

extension OptionalBooleanProperty: QueryAddressableProperty {
    public var queryableProperty: OptionalBooleanProperty<Model, Format> { self }
}

extension OptionalBooleanProperty: AnyDatabaseProperty {
    public var keys: [FieldKey] { self.$field.keys }
    public func input(to input: DatabaseInput) { self.$field.input(to: input) }
    public func output(from output: DatabaseOutput) throws { try self.$field.output(from: output) }
}

extension OptionalBooleanProperty: AnyCodableProperty {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(self.wrappedValue)
    }

    public func decode(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            self.value = nil
        } else {
            self.value = try container.decode(Value.self)
        }
    }
}
