import Foundation
import NIOConcurrencyHelpers

extension Model {
    public typealias Timestamp<Format> = TimestampProperty<Self, Format>
        where Format: TimestampFormat
}

// MARK: Trigger

public enum TimestampTrigger: Sendable {
    case create
    case update
    case delete
    case none
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
        self
    }

    public var wrappedValue: Date? {
        get {
            switch self.value {
                case .none, .some(.none): return nil
                case .some(.some(let value)): return value
            }
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
        self.wrappedValue = date
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
            switch self.$timestamp.value {
                case .some(.some(let timestamp)):
                    .some(self.format.parse(timestamp))
                case .some(.none):
                    .some(.none)
                case .none:
                    .none
            }
        }
        set {
            switch newValue {
                case .some(.some(let newValue)):
                    self.$timestamp.value = .some(self.format.serialize(newValue))
                case .some(.none):
                    self.$timestamp.value = .some(.none)
                case .none:
                    self.$timestamp.value = .none
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

// MARK: Query-addressable

extension TimestampProperty: AnyQueryAddressableProperty {
    public var anyQueryableProperty: any AnyQueryableProperty { self }
    public var queryablePath: [FieldKey] { self.path }
}

extension TimestampProperty: QueryAddressableProperty {
    public var queryableProperty: TimestampProperty<Model, Format> { self }
}

// MARK: Database

extension TimestampProperty: AnyDatabaseProperty {
    public var keys: [FieldKey] {
        self.$timestamp.keys
    }
    
    public func input(to input: any DatabaseInput) {
        self.$timestamp.input(to: input)
    }

    public func output(from output: any DatabaseOutput) throws {
        try self.$timestamp.output(from: output)
    }
}

// MARK: Codable

extension TimestampProperty: AnyCodableProperty {
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(self.wrappedValue)
    }

    public func decode(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            self.value = nil
        } else {
            self.value = try container.decode(Date?.self)
        }
    }
}

// MARK: Timestamp

extension TimestampProperty: AnyTimestamp {
    var key: FieldKey {
        self.$timestamp.key
    }

    var currentTimestampInput: @Sendable () -> DatabaseQuery.Value {
        { [format] in format.serialize(Date()).flatMap { .bind($0) } ?? .null }
    }
}

protocol AnyTimestamp: AnyProperty {
    var key: FieldKey { get }
    var trigger: TimestampTrigger { get }
    /// Serializes the current date in the timestamp's format. It reads only the format, so it outlives the
    /// property it was taken from.
    var currentTimestampInput: @Sendable () -> DatabaseQuery.Value { get }
    func touch(date: Date?)
}

extension AnyTimestamp {
    func touch() {
        self.touch(date: .init())
    }
}

/// What one timestamp of a type is, which never changes for the type: its field's key, what stamps it, how it
/// serializes the current date, and where it stands among an instance's stored properties.
struct TimestampDescriptor: Sendable {
    let key: FieldKey
    let trigger: TimestampTrigger
    let currentInput: @Sendable () -> DatabaseQuery.Value
    /// Its offset among an instance's reflected children, or `nil` where the type's ``Fields/properties`` are
    /// not its own children, as a ``ModelAlias``'s are its model's.
    let childIndex: Int?
}

/// Each type's timestamps, found the first time the type is asked about them.
private let timestampDescriptorsByType = NIOLockedValueBox<[ObjectIdentifier: [TimestampDescriptor]]>([:])

extension Fields {
    /// This type's timestamps, found by reflecting a fresh instance the first time the type is asked, and
    /// remembered since, so a query or a save reflects no instance to learn them.
    static var timestampDescriptors: [TimestampDescriptor] {
        let type = ObjectIdentifier(self)
        if let known = timestampDescriptorsByType.withLockedValue({ $0[type] }) {
            return known
        }
        let found = self.findTimestampDescriptors()
        timestampDescriptorsByType.withLockedValue { $0[type] = found }
        return found
    }

    /// This type's soft-delete timestamp, if it holds one.
    static var deletedTimestampDescriptor: TimestampDescriptor? {
        self.timestampDescriptors.first { $0.trigger == .delete }
    }

    private static func findTimestampDescriptors() -> [TimestampDescriptor] {
        let prototype = self.init()
        let timestamps = prototype.properties.compactMap { $0 as? any AnyTimestamp }
        guard !timestamps.isEmpty else {
            return []
        }
        let children = _FastChildSequence(subject: prototype).map(\.child)
        return timestamps.map { timestamp in
            .init(
                key: timestamp.key,
                trigger: timestamp.trigger,
                currentInput: timestamp.currentTimestampInput,
                childIndex: children.firstIndex { ($0 as? any AnyTimestamp) === timestamp }
            )
        }
    }

    /// The timestamps the given triggers stamp, read from this instance where its type's were found.
    func timestamps(triggeredBy triggers: [TimestampTrigger]) -> [any AnyTimestamp] {
        let descriptors = type(of: self).timestampDescriptors.filter { triggers.contains($0.trigger) }
        guard !descriptors.isEmpty else {
            return []
        }
        let childIndices = descriptors.compactMap(\.childIndex)
        guard childIndices.count == descriptors.count else {
            return self.properties.compactMap { $0 as? any AnyTimestamp }.filter { triggers.contains($0.trigger) }
        }
        let children = _FastChildSequence(subject: self)
        return childIndices.compactMap { children.child(at: $0) as? any AnyTimestamp }
    }

    func touchTimestamps(_ triggers: TimestampTrigger...) {
        let date = Date()
        for timestamp in self.timestamps(triggeredBy: triggers) {
            timestamp.touch(date: date)
        }
    }

    var deletedTimestamp: (any AnyTimestamp)? {
        self.timestamps(triggeredBy: [.delete]).first
    }
}

extension Schema {
    static func excludeDeleted(from query: inout DatabaseQuery) {
        guard let timestamp = self.deletedTimestampDescriptor else {
            return
        }
        let deletedAtField = DatabaseQuery.Field.extendedPath(
            [timestamp.key],
            schema: self.schemaOrAlias,
            space: self.space
        )
        query.filters.append(.group([
            .value(deletedAtField, .equal, .null),
            .value(deletedAtField, .greaterThan, timestamp.currentInput())
        ], .or))
    }
}
