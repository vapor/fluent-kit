public protocol Fields: class, Codable {
    var properties: [String: AnyProperty] { get }
    init()
}

extension FieldKey {
    public static func key<Model, Field>(for field: KeyPath<Model, Field>) -> Self
        where
            Field: FieldProtocol,
            Field.Model == Model
    {
        Model.key(for: field)
    }
}

extension Fields {
    public static var keys: [FieldKey] {
        self.init().fields.values.flatMap {
            $0.keys
        }
    }

    public static func key<Model, Field>(for field: KeyPath<Model, Field>) -> FieldKey
        where
            Field: FieldProtocol,
            Field.Model == Model
    {
         Model.init()[keyPath: field].keys[0]
    }

    public static func path<Field>(for field: KeyPath<Self, Field>) -> [FieldKey]
        where Field: FieldProtocol
    {
         Self.init()[keyPath: field].keys
    }

    /// Indicates whether the model has fields that have been set, but the model
    /// has not yet been saved to the database.
    public var hasChanges: Bool {
        return !self.input.values.isEmpty
    }

    public var input: DatabaseInput {
        var input = DatabaseInput()
        self.properties.values.forEach { field in
            field.input(to: &input)
        }
        return input
    }

    public func output(from output: DatabaseOutput) throws {
        try self.properties.values.forEach { field in
            try field.output(from: output)
        }
    }

    public var fields: [String: AnyField] {
        self.properties.compactMapValues { $0 as? AnyField }
    }

    public var properties: [String: AnyProperty] {
        .init(uniqueKeysWithValues:
            Mirror(reflecting: self).children.compactMap { child in
                guard let label = child.label else {
                    return nil
                }
                guard let field = child.value as? AnyProperty else {
                    return nil
                }
                // remove underscore
                return (String(label.dropFirst()), field)
            }
        )
    }
}
