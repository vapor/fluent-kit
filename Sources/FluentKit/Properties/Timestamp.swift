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
    let formatter: AnyTimestampFormatter

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

    public convenience init(key: FieldKey, on trigger: TimestampTrigger) {
        self.init(key: key, on: trigger, format: .default)
    }

    public init<Formatter>(key: FieldKey, on trigger: TimestampTrigger, format: TimestampFormat<Formatter>) {
        self.field = .init(key: key)
        self.trigger = trigger
        self.formatter = format.formatter
    }

    public func touch(date: Date?) {
        self.field.inputValue = .bind(date)
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
        let timestamp = self.value.map { date in self.formatter.timestamp(from: date) } ?? Optional<Date>.none
        input.values[self.field.key] = .bind(timestamp)
    }

    public func output(from output: DatabaseOutput) throws {
        self.field.inputValue = nil
        guard output.contains(self.field.key) else { return }

        do {
            let date = try self.formatter.decode(at: self.field.key, from: output)
            self.field.outputValue = date
        } catch {
            throw FluentError.invalidField(name: self.field.key.description, valueType: Value.self, error: error)
        }
    }

    public func encode(to encoder: Encoder) throws {
        let timestamp = self.value.map(self.formatter.timestamp(from:)) ?? Optional<Date>.none
        try timestamp.encode(to: encoder)
    }

    public func decode(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            self.field.value = nil
        } else {
            let timestamp = try self.formatter.timestampType.init(from: decoder)
            self.field.inputValue = .bind(self.formatter.date(from: timestamp))
        }
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


// MARK: - Timestamp Formatter

public protocol AnyTimestampFormatter {
    var timestampType: Codable.Type { get }

    func timestamp(from date: Date) -> Codable
    func date(from timestamp: Codable) -> Date?

    func decode(at key: FieldKey, from output: DatabaseOutput) throws -> Date?
}

public protocol TimestampFormatter: AnyTimestampFormatter {
    associatedtype Timestamp: Codable

    func timestamp(from date: Date) -> Timestamp
    func date(from timestamp: Timestamp) -> Date?
}

extension TimestampFormatter {
    public var timestampType: Codable.Type { Timestamp.self }


    public func timestamp(from date: Date) -> Codable {
        return self.timestamp(from: date) as Timestamp
    }

    public func date(from timestamp: Codable) -> Date? {
        return (timestamp as? Timestamp).flatMap(self.date(from:))
    }


    public func decode(at key: FieldKey, from output: DatabaseOutput) throws -> Date? {
        let timestamp = try output.decode(key, as: Timestamp?.self)
        return timestamp.flatMap(self.date(from:))
    }
}


extension DateFormatter: TimestampFormatter {
    public func timestamp(from date: Date) -> String { self.string(from: date) }
}

extension ISO8601DateFormatter: TimestampFormatter {
    public func timestamp(from date: Date) -> String { self.string(from: date) }
}

public struct UnixTimestampFormatter: TimestampFormatter {
    public func timestamp(from date: Date) -> Double { date.timeIntervalSince1970 }
    public func date(from timestamp: Double) -> Date? { Date(timeIntervalSince1970: timestamp) }
}

public struct DefaultTimestampFormatter: TimestampFormatter {
    public func timestamp(from date: Date) -> Date { date }
    public func date(from timestamp: Date) -> Date? { timestamp }
}


private final class TimestampFormatterCache {
    static func formatter<Formatter>(for id: String, factory: () -> Formatter) -> Formatter where Formatter: TimestampFormatter {
        if let formatter = self.current.currentValue?.cache[id] as? Formatter { return formatter }

        let new = factory()

        if self.current.currentValue == nil { self.current.currentValue = TimestampFormatterCache() }
        self.current.currentValue?.cache[id] = new

        return new
    }

    private static var current: ThreadSpecificVariable<TimestampFormatterCache> = .init()

    var cache: [String: AnyTimestampFormatter] = [:]
}


public struct TimestampFormat<Formatter> where Formatter: TimestampFormatter {
    public let id: String
    private let factory: () -> Formatter

    public var formatter: Formatter { TimestampFormatterCache.formatter(for: self.id, factory: self.factory) }

    public init(_ id: String, formatter: @escaping () -> Formatter) {
        self.id = id
        self.factory = formatter
    }
}

extension TimestampFormat where Formatter == ISO8601DateFormatter {
    public static let iso8601 = TimestampFormat("iso8601", formatter: ISO8601DateFormatter.init)
}

extension TimestampFormat where Formatter == UnixTimestampFormatter {
    public static let unix = TimestampFormat("unix", formatter: UnixTimestampFormatter.init)
}

extension TimestampFormat where Formatter == DefaultTimestampFormatter {
    public static let `default` = TimestampFormat("default", formatter: DefaultTimestampFormatter.init)
}
