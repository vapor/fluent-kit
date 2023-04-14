extension Fields {
    public typealias Boolean<Format> = BooleanProperty<Self, Format>
        where Format: BooleanPropertyFormat
}

/// A Fluent model property which represents a boolean (true/false) value.
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
///         // This field will be stored using the database's native boolean format.
///         @Field(key: "rawEnabled") var rawEnabled: Bool
///
///         // This field will be stored as a string, either "true" or "false".
///         @Boolean(key: "enabled", format: .trueFalse) var enabled: Bool
///
///         init() {}
///     }
///
///     struct MyModelMigration: AsyncMigration {
///         func prepare(on database: Database) async throws -> Void {
///             try await database.schema(MyModel.schema)
///                 .id()
///                 .field("rawEnabled", .bool, .required)
///                 .field("enabled", .string, .required)
///                 .create()
///         }
///
///         func revert(on database: Database) async throws -> Void { try await database.schema(MyModel.schema).delete() }
///     }
///
/// - Note: See also ``OptionalBooleanProperty`` and ``BooleanPropertyFormat``.
@propertyWrapper
public final class BooleanProperty<Model, Format>
    where Model: FluentKit.Fields, Format: BooleanPropertyFormat
{
    @FieldProperty<Model, Format.Value>
    public var field: Format.Value
    public let format: Format

    public var projectedValue: BooleanProperty<Model, Format> { self }

    public var wrappedValue: Bool {
        get {
            guard let value = self.value else {
                fatalError("Cannot access bool field before it is initialized or fetched: \(self.$field.key)")
            }
            return value
        }
        set { self.value = newValue }
    }

    public init(key: FieldKey, format: Format) {
        self._field = .init(key: key)
        self.format = format
    }
}

extension BooleanProperty where Format == DefaultBooleanPropertyFormat {
    public convenience init(key: FieldKey) {
        self.init(key: key, format: .default)
    }
}

/// This is a workaround for Swift 5.4's inability to correctly infer the format type
/// using the `Self` constraints on the various static properties.
extension BooleanProperty {
    public convenience init(key: FieldKey, format factory: BooleanPropertyFormatFactory<Format>) {
        self.init(key: key, format: factory.format)
    }
}

extension BooleanProperty: AnyProperty {}

extension BooleanProperty: Property {
    public var value: Bool? {
        get { self.$field.value.map { self.format.parse($0)! } }
        set { self.$field.value = newValue.map { self.format.serialize($0) } }
    }
}

extension BooleanProperty: AnyQueryableProperty {
    public var path: [FieldKey] { self.$field.path }
}

extension BooleanProperty: QueryableProperty {
    public static func queryValue(_ value: Bool) -> DatabaseQuery.Value {
        .bind(Format.init().serialize(value))
    }
}

extension BooleanProperty: AnyQueryAddressableProperty {
    public var anyQueryableProperty: AnyQueryableProperty { self }
    public var queryablePath: [FieldKey] { self.path }
}

extension BooleanProperty: QueryAddressableProperty {
    public var queryableProperty: BooleanProperty<Model, Format> { self }
}

extension BooleanProperty: AnyDatabaseProperty {
    public var keys: [FieldKey] { self.$field.keys }
    public func input(to input: DatabaseInput) { self.$field.input(to: input) }
    public func output(from output: DatabaseOutput) throws { try self.$field.output(from: output) }
}

extension BooleanProperty: AnyCodableProperty {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(self.wrappedValue)
    }

    public func decode(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        self.value = try container.decode(Value.self)
    }
}
