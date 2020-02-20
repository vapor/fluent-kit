protocol AnyProperty: class {
    var keys: [FieldKey] { get }
    func input(to input: inout DatabaseInput)
    func output(from output: DatabaseOutput) throws
    func encode(to encoder: Encoder) throws
    func decode(from decoder: Decoder) throws
}

extension Fields {
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
