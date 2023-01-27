public protocol Fields: AnyObject, Codable {
    var properties: [AnyProperty] { get }
    init()
    func input(to input: DatabaseInput)
    func output(from output: DatabaseOutput) throws
}

// MARK: Has Changes

extension Fields {
    /// Indicates whether the model has fields that have been set, but the model
    /// has not yet been saved to the database.
    public var hasChanges: Bool {
        let input = HasChangesInput()
        self.input(to: input)
        return input.hasChanges
    }
}

private final class HasChangesInput: DatabaseInput {
    var hasChanges: Bool

    init() {
        self.hasChanges = false
    }

    func set(_ value: DatabaseQuery.Value, at key: FieldKey) {
        self.hasChanges = true
    }
}

// MARK: Path

extension Fields {
    public static func path<Property>(for field: KeyPath<Self, Property>) -> [FieldKey]
        where Property: AnyQueryableProperty
    {
         Self.init()[keyPath: field].path
    }
}

// MARK: Database

extension Fields {
    public static var keys: [FieldKey] {
        self.init().properties.compactMap {
            $0 as? AnyDatabaseProperty
        }.flatMap {
            $0.keys
        }
    }

    public func input(to input: DatabaseInput) {
        self.properties.compactMap {
            $0 as? AnyDatabaseProperty
        }.forEach { field in
            field.input(to: input)
        }
    }

    public func output(from output: DatabaseOutput) throws {
        try self.properties.compactMap {
            $0 as? AnyDatabaseProperty
        }.forEach { field in
            try field.output(from: output)
        }
    }
}

// MARK: Properties

extension Fields {
    public var properties: [AnyProperty] {
        return _FastChildSequence(subject: self).compactMap { $1 as? AnyProperty }
    }

    internal var codableProperties: [SomeCodingKey: AnyCodableProperty] {
        return .init(uniqueKeysWithValues: _FastChildSequence(subject: self).compactMap {
            guard let value = $1 as? AnyCodableProperty,
                  let nameC = $0, nameC.pointee != 0, nameC.advanced(by: 1).pointee != 0,
                  let name = String(utf8String: nameC.advanced(by: 1))
            else {
                return nil
            }
            return (.init(stringValue: name), value)
        })
    }
}

// MARK: Collect Input

extension Fields {
    internal func collectInput() -> [FieldKey: DatabaseQuery.Value] {
        let input = DictionaryInput()
        self.input(to: input)
        return input.storage
    }
}

final class DictionaryInput: DatabaseInput {
    var storage: [FieldKey: DatabaseQuery.Value]
    init() {
        self.storage = [:]
    }

    func set(_ value: DatabaseQuery.Value, at key: FieldKey) {
        self.storage[key] = value
    }
}
