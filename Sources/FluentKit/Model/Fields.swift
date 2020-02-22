public protocol Fields: class, Codable {
    var fields: [String: Any] { get }
    init()
}

extension FieldKey {
    public static func key<Model, Field>(for field: KeyPath<Model, Field>) -> Self
        where
            Field: QueryField,
            Field.Model == Model
    {
         Model.init()[keyPath: field].key
    }
}

extension Fields {
    public static func key<Field>(for field: KeyPath<Self, Field>) -> FieldKey
        where Field: QueryField
    {
         Self.init()[keyPath: field].key
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

    static var keys: [FieldKey] {
        self.init().keys
    }
    
    var keys: [FieldKey] {
        self.fields.values.compactMap {
            $0 as? AnyProperty
        }.flatMap {
            $0.keys
        }
    }

    var input: DatabaseInput {
        var input = DatabaseInput()
        self.properties.forEach { (name, property) in
            property.input(to: &input)
        }
        return input
    }

    func output(from output: DatabaseOutput) throws {
        try self.fields.values.forEach { field in
            try (field as! AnyProperty).output(from: output)
        }
    }
}


extension Fields {
    public var fields: [String: Any] {
        var fields: [String: Any] = [:]
        for child in Mirror(reflecting: self).children {
            fields[String(child.label!.dropFirst())] = child.value as? AnyProperty
        }
        return fields
    }

    var properties: [(String, AnyProperty)] {
        return Mirror(reflecting: self)
            .children
            .compactMap
        { child in
            guard let label = child.label else {
                return nil
            }
            guard let property = child.value as? AnyProperty else {
                return nil
            }
            // remove underscore
            return (String(label.dropFirst()), property)
        }
    }
}
