extension Model {
    public typealias Timestamp<Format> = TimestampProperty<Self, Format>
        where Format: TimestampFormat
}

// MARK: Trigger

public enum TimestampTrigger {
    case create
    case update
    case delete
}

// MARK: Type

@propertyWrapper
public final class TimestampProperty<Model, Format>
    where Model: FluentKit.Model, Format: TimestampFormat
{
    @OptionalFieldProperty<Model, Format.Value>
    public var timestamp: Format.Value?

    public let trigger: TimestampTrigger
    let format: Format

    public var projectedValue: TimestampProperty<Model, Format> {
        return self
    }

    public var wrappedValue: Date? {
        get {
            self.value ?? nil
        }
        set {
            self.value = .some(newValue)
        }
    }

    public convenience init(
        key: FieldKey,
        on trigger: TimestampTrigger,
        format: TimestampFormatFactory<Format>
    ) {
        self.init(key: key, on: trigger, format: format.makeFormat())
    }

    public init(key: FieldKey, on trigger: TimestampTrigger, format: Format) {
        self._timestamp = .init(key: key)
        self.trigger = trigger
        self.format = format
    }

    public func touch(date: Date?) {
        self.value = date
    }
}

extension TimestampProperty where Format == DefaultTimestampFormat {
    public convenience init(key: FieldKey, on trigger: TimestampTrigger) {
        self.init(key: key, on: trigger, format: .default)
    }
}

extension TimestampProperty: CustomStringConvertible {
    public var description: String {
        "@\(Model.self).Timestamp(key: \(self.key), trigger: \(self.trigger))"
    }
}

// MARK: Property

extension TimestampProperty: AnyProperty { }

extension TimestampProperty: Property {
    public var value: Date?? {
        get {
            self.$timestamp.value.flatMap {
                .some($0.flatMap { self.format.parse($0) })
            }
        }
        set {
            self.$timestamp.value = newValue.flatMap {
                .some($0.flatMap { self.format.serialize($0) })
            }
        }
    }
}

// MARK: Queryable

extension TimestampProperty: AnyQueryableProperty {
    public var path: [FieldKey] {
        self.$timestamp.path
    }
}

extension TimestampProperty: QueryableProperty { }

// MARK: Database

extension TimestampProperty: AnyDatabaseProperty {
    public var keys: [FieldKey] {
        self.$timestamp.keys
    }
    
    public func input(to input: DatabaseInput) {
        self.$timestamp.input(to: input)
    }

    public func output(from output: DatabaseOutput) throws {
        try self.$timestamp.output(from: output)
    }
}

// MARK: Codable

extension TimestampProperty: AnyCodableProperty {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(self.value)
    }

    public func decode(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        self.value = try container.decode(Date?.self)
    }
}

// MARK: Timestamp

extension TimestampProperty: AnyTimestamp {
    var key: FieldKey {
        self.$timestamp.key
    }

    var currentTimestampInput: DatabaseQuery.Value {
        self.format.serialize(Date()).flatMap { .bind($0) } ?? .null
    }
}

protocol AnyTimestamp: AnyProperty {
    var key: FieldKey { get }
    var trigger: TimestampTrigger { get }
    var currentTimestampInput: DatabaseQuery.Value { get }
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
            [timestamp.key],
            schema: self.schemaOrAlias
        )
        query.filters.append(.group([
            .value(deletedAtField, .equal, .null),
            .value(deletedAtField, .greaterThan, timestamp.currentTimestampInput)
        ], .or))
    }
}
