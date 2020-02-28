public protocol PropertyProtocol: AnyProperty {
    associatedtype Model: Fields
    associatedtype Value: Codable
    var value: Value? { get set }
    var anyFieldValue: Any? { get }
    var anyFieldValueType: Any.Type { get }
}

public protocol AnyProperty: class {
    var fields: [AnyField] { get }
    var path: [FieldKey] { get }
    func input(to input: inout DatabaseInput)
    func output(from output: DatabaseOutput) throws
    func encode(to encoder: Encoder) throws
    func decode(from decoder: Decoder) throws
}

extension PropertyProtocol {
    public var anyFieldValue: Any? {
        self.value
    }

    public var anyFieldValueType: Any.Type {
        Value.self
    }
}

extension AnyProperty {
    public var path: [FieldKey] {
        return []
    }
}

public protocol FieldProtocol: AnyField, PropertyProtocol { }

public protocol AnyField: AnyProperty { }
