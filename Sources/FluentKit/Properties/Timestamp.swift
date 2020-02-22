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
    public typealias Value = Date?

    public let field: FieldProperty<Model, Date?>

    public let trigger: TimestampTrigger

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

    public var projectedValue: TimestampProperty<Model> {
        return self
    }

    public var wrappedValue: Date? {
        get {
            return self.field.wrappedValue
        }
        set {
            self.field.wrappedValue = newValue
        }
    }

    public init(key: FieldKey, on trigger: TimestampTrigger) {
        self.field = .init(key: key)
        self.trigger = trigger
    }

    public func touch(date: Date?) {
        self.inputValue = .bind(date)
    }
}

extension TimestampProperty: AnyProperty {
    var keys: [FieldKey] {
        [self.key]
    }
    
    func input(to input: inout DatabaseInput) {
        self.field.input(to: &input)
    }

    func output(from output: DatabaseOutput) throws {
        try self.field.output(from: output)
    }

    func encode(to encoder: Encoder) throws {
        try self.field.encode(to: encoder)
    }

    func decode(from decoder: Decoder) throws {
        try self.field.decode(from: decoder)
    }
}

extension TimestampProperty: AnyTimestamp { }

extension TimestampProperty: FieldProtocol {
    public var path: [FieldKey] {
        self.field.path
    }
}

protocol AnyTimestamp: AnyProperty {
    var key: FieldKey { get }
    var trigger: TimestampTrigger { get }
    func touch(date: Date?)
}

extension AnyTimestamp {
    func touch() {
        self.touch(date: .init())
    }
}

extension Fields {
    var timestamps: [(Substring, AnyTimestamp)] {
        self.properties.compactMap {
            guard let value = $1 as? AnyTimestamp else {
                return nil
            }
            return ($0, value)
        }
    }
    func touchTimestamps(_ triggers: TimestampTrigger...) {
        return self.touchTimestamps(triggers)
    }

    private func touchTimestamps(_ triggers: [TimestampTrigger]) {
        let date = Date()
        self.timestamps.forEach { (label, timestamp) in
            if triggers.contains(timestamp.trigger) {
                timestamp.touch(date: date)
            }
        }
    }

    var deletedTimestamp: AnyTimestamp? {
        return self.timestamps.filter({ $0.1.trigger == .delete }).first?.1
    }

    func excludeDeleted(from query: inout DatabaseQuery, schema: String) {
        guard let timestamp = self.deletedTimestamp else {
            return
        }

        let deletedAtField = DatabaseQuery.Field.field(
            path: [timestamp.key],
            schema: schema,
            alias: nil
        )
        let isNull = DatabaseQuery.Filter.value(deletedAtField, .equal, .null)
        let isFuture = DatabaseQuery.Filter.value(deletedAtField, .greaterThan, .bind(Date()))
        query.filters.append(.group([isNull, isFuture], .or))
    }
}
