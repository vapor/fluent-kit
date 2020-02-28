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
        Model.path(for: field)[0]
    }
}

extension Fields {
    public static var keys: [[FieldKey]] {
        self.init().fields.flatMap {
            $0.fields.map { $0.path }
        }
    }

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

    public var fields: [AnyField] {
        self.properties.values.flatMap { $0.fields }
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
