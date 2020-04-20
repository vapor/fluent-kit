import EchoProperties

public protocol Fields: class, Codable {
    var properties: [AnyProperty] { get }
    init()
}

extension Fields {
    public static func path<Field>(for field: KeyPath<Self, Field>) -> [FieldKey]
        where Field: FieldProtocol
    {
         Self.init()[keyPath: field].path
    }

    /// Indicates whether the model has fields that have been set, but the model
    /// has not yet been saved to the database.
    public var hasChanges: Bool {
        return !self.input.values.isEmpty
    }

    public var input: DatabaseInput {
        var input = DatabaseInput()
        self.properties.forEach { field in
            field.input(to: &input)
        }
        return input
    }

    public func output(from output: DatabaseOutput) throws {
        try self.properties.forEach { field in
            try field.output(from: output)
        }
    }

    public var properties: [AnyProperty] {
        Reflection.allKeyPaths(for: self).compactMap {
            self[keyPath: $0] as? AnyProperty
        }
    }

    // Internal

    var labeledProperties: [String: AnyProperty] {
        .init(uniqueKeysWithValues:
            Reflection.allNamedKeyPaths(for: self).compactMap {
                guard let value = self[keyPath: $0.keyPath] as? AnyProperty else {
                    return nil
                }
            
                return (String($0.name.dropFirst()), value)
            }
        )
    }

    static var keys: [[FieldKey]] {
        func collect(
            _ properties: [AnyProperty],
            prefix: [FieldKey] = [],
            into keys: inout [[FieldKey]]
        ) {
            properties.forEach {
                if $0 is AnyField {
                    keys.append(prefix + $0.path)
                }
                collect($0.nested, prefix: prefix + $0.path, into: &keys)
            }
        }
        var keys: [[FieldKey]] = []
        collect(self.init().properties, into: &keys)
        return keys
    }

}
