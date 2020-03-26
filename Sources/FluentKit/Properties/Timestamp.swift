import class Foundation.ISO8601DateFormatter
import class Foundation.DateFormatter
import class NIO.ThreadSpecificVariable

extension Fields {
    public typealias Timestamp = TimestampProperty<Self>
}

public enum TimestampTrigger {
    case create
    case update
    case delete
}

@propertyWrapper
public final class TimestampProperty<Model>
    where Model: FluentKit.Fields
{
    public let field: Model.OptionalField<Date>
    public let trigger: TimestampTrigger

    public var projectedValue: TimestampProperty<Model> {
        return self
    }

    public var wrappedValue: Date? {
        get {
            self.value
        }
        set {
            self.value = newValue
        }
    }

    public init(key: FieldKey, on trigger: TimestampTrigger) {
        self.field = .init(key: key)
        self.trigger = trigger
    }

    public init(key: FieldKey, on trigger: TimestampTrigger, format: TimestampFormat) {
        let converter: AnyFieldValueConverter<Date?>
        switch format {
        case .default:
            converter = AnyFieldValueConverter(DefaultFieldValueConverter(Model.self, key: key))
        case let .custom(_, formatter):
            converter = AnyFieldValueConverter(TimestampValueConverter<Model>(key: key, formatter: formatter()))
        }

        self.field = .init(key: key, converter: converter)
        self.trigger = trigger
    }

    public func touch(date: Date?) {
        self.field.inputValue = self.field.converter.databaseValue(from: date)
    }
}

extension TimestampProperty: PropertyProtocol {
    public var value: Date? {
        get {
            self.field.value
        }
        set {
            self.field.value = newValue
        }
    }
}

extension TimestampProperty: FieldProtocol { }

extension TimestampProperty: AnyProperty {
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
        try self.field.output(from: output)
    }

    public func encode(to encoder: Encoder) throws {
        try self.field.encode(to: encoder)
    }

    public func decode(from decoder: Decoder) throws {
        try self.field.decode(from: decoder)
    }
}

extension TimestampProperty: AnyTimestamp { }

protocol AnyTimestamp: AnyProperty {
    var trigger: TimestampTrigger { get }
    func touch(date: Date?)
}

extension AnyTimestamp {
    func touch() {
        self.touch(date: .init())
    }
}

extension Fields {
    var timestamps: [AnyTimestamp] {
        self.properties.compactMap {
            $0 as? AnyTimestamp
        }
    }
    
    func touchTimestamps(_ triggers: TimestampTrigger...) {
        return self.touchTimestamps(triggers)
    }

    private func touchTimestamps(_ triggers: [TimestampTrigger]) {
        let date = Date()
        self.timestamps.forEach { timestamp in
            if triggers.contains(timestamp.trigger) {
                timestamp.touch(date: date)
            }
        }
    }

    var deletedTimestamp: AnyTimestamp? {
        self.timestamps.filter { $0.trigger == .delete }.first
    }
}

extension Schema {
    static func excludeDeleted(from query: inout DatabaseQuery) {
        guard let timestamp = self.init().deletedTimestamp else {
            return
        }

        let deletedAtField = DatabaseQuery.Field.path(
            timestamp.path,
            schema: self.schemaOrAlias
        )
        let isNull = DatabaseQuery.Filter.value(deletedAtField, .equal, .null)
        let isFuture = DatabaseQuery.Filter.value(deletedAtField, .greaterThan, .bind(Date()))
        query.filters.append(.group([isNull, isFuture], .or))
    }
}


public protocol TimestampFormatter {
    func string(from date: Date) -> String
    func date(from string: String) -> Date?
}

extension DateFormatter: TimestampFormatter { }
extension ISO8601DateFormatter: TimestampFormatter { }

public enum TimestampFormat {
    public static let iso8601 = TimestampFormat.custom("iso8601", formatter: ISO8601DateFormatter.init)

    case `default`
    case custom(String, formatter: () -> TimestampFormatter)
}

public struct TimestampValueConverter<Model>: FieldValueConverter where Model: Fields {
    public typealias Value = Date?

    public let formatter: TimestampFormatter
    public let key: FieldKey

    public init(key: FieldKey, formatter: TimestampFormatter) {
        self.formatter = formatter
        self.key = key
    }

    public func value(from databaseValue: DatabaseQuery.Value) -> Value? {
        let string: String?
        switch databaseValue {
        case let .bind(bind): string = bind as? String
        case .default: return Date()
        case .null: return nil
        case .array, .dictionary, .enumCase, .custom:
            fatalError("Unexpected input value type for '\(Model.self).\(self.key)': \(databaseValue)")
        }

        return string.flatMap(self.formatter.date(from:))
    }

    public func databaseValue(from value: Value) -> DatabaseQuery.Value {
        return .bind(value.map(self.formatter.string(from:)))
    }

    public func decode(from output: DatabaseOutput) throws -> Value {
        guard output.contains(self.key) else { return nil }
        guard let string = try output.decode(self.key, as: Optional<String>.self) else { return nil }

        return self.formatter.date(from: string)
    }

    public func encode(_ value: Value, to container: inout SingleValueEncodingContainer) throws {
        try container.encode(value.map(self.formatter.string(from:)))
    }

    public func decode(from container: SingleValueDecodingContainer) throws -> Value {
        if container.decodeNil() { return nil }

        let string = try container.decode(String.self)
        return self.formatter.date(from: string)
    }
}
