protocol AnyProperty: class {
    func output(from output: DatabaseOutput) throws
    func encode(to encoder: Encoder) throws
    func decode(from decoder: Decoder) throws
}

extension AnyProperty where Self: FieldRepresentable {
    func output(from output: DatabaseOutput) throws {
        try self.field.output(from: output)
    }

    func encode(to encoder: Encoder) throws {
        try self.field.encode(to: encoder)
    }

    func decode(from decoder: Decoder) throws {
        try self.field.decode(from: decoder)
    }
}

extension AnyModel {
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
