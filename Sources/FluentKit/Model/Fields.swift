public protocol Fields: class, Codable {
    var fields: [String: AnyField] { get }
    init()
}

extension FieldKey {
    public static func key<Model, Field>(for field: KeyPath<Model, Field>) -> Self
        where
            Field: QueryField,
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
            Field: QueryField,
            Field.Model == Model
    {
         Model.init()[keyPath: field].key
    }

    public static func path<Field>(for field: KeyPath<Self, Field>) -> [FieldKey]
        where Field: FilterField
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
        self.fields.values.forEach { field in
            field.input(to: &input)
        }
        return input
    }

    public func output(from output: DatabaseOutput) throws {
        try self.fields.values.forEach { field in
            try field.output(from: output)
        }
    }

    public var fields: [String: AnyField] {
        return .init(uniqueKeysWithValues:
            Mirror(reflecting: self).children.compactMap { child in
                guard let label = child.label else {
                    return nil
                }
                guard let field = child.value as? AnyField else {
                    return nil
                }
                // remove underscore
                return (String(label.dropFirst()), field)
            }
        )
    }
}
