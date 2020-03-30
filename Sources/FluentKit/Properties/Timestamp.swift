import class Foundation.ISO8601DateFormatter
import class Foundation.DateFormatter
import class NIO.ThreadSpecificVariable

extension Fields {
    public typealias Timestamp<Formatter> = TimestampProperty<Self, Formatter>
        where Formatter: TimestampFormatter
}

extension TimestampProperty where Formatter == UnixTimestampFormatter {
    public convenience init(key: FieldKey, on trigger: TimestampTrigger) {
        self.init(key: key, on: trigger, format: .unix)
    }
}

public enum TimestampTrigger {
    case create
    case update
    case delete
}

@propertyWrapper
public final class TimestampProperty<Model, Formatter>
    where Model: FluentKit.Fields, Formatter: TimestampFormatter
{
    public let field: Model.OptionalField<Date>
    public let trigger: TimestampTrigger
    let formatter: TimestampFormat<Formatter>

    public var projectedValue: TimestampProperty<Model, Formatter> {
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

    public init(key: FieldKey, on trigger: TimestampTrigger, format: TimestampFormat<Formatter>) {
        self.field = .init(key: key)
        self.trigger = trigger
        self.formatter = format
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
        input.values[self.field.key] = .bind(self.value.map(self.formatter.timestamp(from:)))
    }

    public func output(from output: DatabaseOutput) throws {
        self.field.inputValue = nil
        guard output.contains(self.field.key) else { return }

        do {
            let string = try output.decode(self.field.key, as: Formatter.Timestamp?.self)
            self.field.outputValue = string.flatMap(self.formatter.date(from:))
        } catch {
            throw FluentError.invalidField(name: self.field.key.description, valueType: Value.self, error: error)
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(self.wrappedValue.flatMap(self.formatter.timestamp(from:)))
    }

    public func decode(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            self.field.value = nil
        } else {
            let string = try container.decode(Formatter.Timestamp.self)
            self.field.inputValue = .bind(self.formatter.date(from: string))
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

public protocol AnyTimestampFormatter { }

public protocol TimestampFormatter: AnyTimestampFormatter {
    associatedtype Timestamp: Codable

    func timestamp(from date: Date) -> Timestamp
    func date(from timestamp: Timestamp) -> Date?
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

    public func timestamp(from date: Date) -> Formatter.Timestamp { self.formatter.timestamp(from: date) }
    public func date(from timestamp: Formatter.Timestamp) -> Date? { self.formatter.date(from: timestamp) }
}


extension TimestampFormat where Formatter == ISO8601DateFormatter {
    public static let iso8601 = TimestampFormat("iso8601", formatter: ISO8601DateFormatter.init)
}

extension TimestampFormat where Formatter == UnixTimestampFormatter {
    public static let unix = TimestampFormat("unix", formatter: UnixTimestampFormatter.init)
}
