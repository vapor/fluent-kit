public protocol Fields: class, Codable {
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
    
    var keys: [FieldKey] {
        self.properties.flatMap { (label, property) in
            property.keys
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
        try self.properties.forEach { (_, property) in
            try property.output(from: output)
        }
    }
}
