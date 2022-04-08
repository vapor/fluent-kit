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
#if compiler(<5.7) && compiler(>=5.2) && swift(>=5.2)
        let type = _getNormalizedType(self, type: Swift.type(of: self))
        let childCount = _getChildCount(self, type: type)
        return (0 ..< childCount).compactMap({
            var nameC: UnsafePointer<CChar>? = nil
            var freeFunc: (@convention(c) (UnsafePointer<CChar>?) -> Void)? = nil
            defer { freeFunc?(nameC) }
            return _getChild(of: self, type: Self.self, index: $0, outName: &nameC, outFreeFunc: &freeFunc) as? AnyProperty
        })
#else
        Mirror(reflecting: self).children.compactMap {
            $0.value as? AnyProperty
        }
#endif
    }

    internal var labeledProperties: [String: AnyCodableProperty] {
#if compiler(<5.7) && compiler(>=5.2) && swift(>=5.2)
        let type = _getNormalizedType(self, type: Swift.type(of: self))
        let childCount = _getChildCount(self, type: type)

        return .init(uniqueKeysWithValues:
            (0 ..< childCount).compactMap({
                var nameC: UnsafePointer<CChar>? = nil
                var freeFunc: (@convention(c) (UnsafePointer<CChar>?) -> Void)? = nil
                defer { freeFunc?(nameC) }
                guard let value = _getChild(
                        of: self, type: Self.self, index: $0, outName: &nameC, outFreeFunc: &freeFunc
                      ) as? AnyCodableProperty,
                      let nameCC = nameC, nameCC.pointee != 0, nameCC.advanced(by: 1).pointee != 0,
                      let name = String(validatingUTF8: nameCC.advanced(by: 1))
                else { return nil }
                return (name, value)
            })
        )
#else
        .init(uniqueKeysWithValues:
            Mirror(reflecting: self).children.compactMap { child in
                guard let label = child.label else {
                    return nil
                }
                guard let field = child.value as? AnyCodableProperty else {
                    return nil
                }
                // remove underscore
                return (String(label.dropFirst()), field)
            }
        )
#endif
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
