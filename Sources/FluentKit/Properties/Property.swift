protocol AnyProperty: class {
    var keys: [FieldKey] { get }
    func input(to input: inout DatabaseInput)
    func output(from output: DatabaseOutput) throws
    func encode(to encoder: Encoder) throws
    func decode(from decoder: Decoder) throws
}

struct DatabaseInput {
    var fields: [FieldKey: DatabaseQuery.Value]
    init() {
        self.fields = [:]
    }
}

extension Fields {
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

extension Fields {
    var properties: [(String, AnyProperty)] {
        return Mirror(reflecting: self)
            .children
            .compactMap { child in
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
