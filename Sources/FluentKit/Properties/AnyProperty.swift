protocol AnyProperty: class {
    var keys: [FieldKey] { get }
    func input(to input: inout DatabaseInput)
    func output(from output: DatabaseOutput) throws
    func encode(to encoder: Encoder) throws
    func decode(from decoder: Decoder) throws
}
