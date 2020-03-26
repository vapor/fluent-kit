import class Foundation.ISO8601DateFormatter
import class Foundation.DateFormatter

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
    let formatter: TimestampFormat.Instance

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
        self.formatter = .default
    }

    public init(key: FieldKey, on trigger: TimestampTrigger, format: TimestampFormat) {
        self.field = .init(key: key)
        self.trigger = trigger
        self.formatter = format.initialize()
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
        switch self.formatter {
        case .default: self.field.input(to: &input)
        case let .custom(formatter): input.values[self.field.key] = .bind(self.value.map(formatter.string(from:)))
        }
    }

    public func output(from output: DatabaseOutput) throws {
        switch self.formatter {
        case .default: try self.field.output(from: output)
        case let .custom(formatter):
            self.field.inputValue = nil
            guard output.contains(self.field.key) else { return }

            do {
                let string = try output.decode(self.field.key, as: String?.self)
                self.field.outputValue = string.flatMap(formatter.date(from:))
            } catch {
                throw FluentError.invalidField(name: self.field.key.description, valueType: Value.self, error: error)
            }
        }
    }

    public func encode(to encoder: Encoder) throws {
        switch self.formatter {
        case .default: try self.field.encode(to: encoder)
        case let .custom(formatter):
            var container = encoder.singleValueContainer()
            try container.encode(self.wrappedValue.flatMap(formatter.string(from:)))
        }
    }

    public func decode(from decoder: Decoder) throws {
        switch self.formatter {
        case .default: try self.field.decode(from: decoder)
        case let .custom(formatter):
            let container = try decoder.singleValueContainer()
            if container.decodeNil() {
                self.field.value = nil
            } else {
                let string = try container.decode(String.self)
                self.field.inputValue = .bind(formatter.date(from: string))
            }
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

    func initialize() -> Instance {
        switch self {
        case .default: return .default
        case let .custom(_, formatter): return .custom(formatter())
        }
    }

    enum Instance {
        case `default`
        case custom(TimestampFormatter)
    }
}
