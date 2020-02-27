public protocol PropertyProtocol: AnyProperty {
    associatedtype Model: Fields
    associatedtype Value: Codable
}

public protocol AnyProperty: class {
    func input(to input: inout DatabaseInput)
    func output(from output: DatabaseOutput) throws
    func encode(to encoder: Encoder) throws
    func decode(from decoder: Decoder) throws
}

public protocol FieldProtocol: AnyField, PropertyProtocol {
    associatedtype FieldValue: Codable
    var fieldValue: FieldValue { get set }
}

extension FieldProtocol {
    public var anyFieldValue: Any {
        self.fieldValue
    }

    public var anyFieldValueType: Any.Type {
        FieldValue.self
    }
}

public protocol AnyField: AnyProperty {
    var keys: [FieldKey] { get }
    var anyFieldValue: Any { get }
    var anyFieldValueType: Any.Type { get }
}

public protocol FilterField {
    associatedtype Model: Fields
    associatedtype QueryValue: Codable
    var path: [FieldKey] { get }
}

public protocol QueryField: FilterField {
    var key: FieldKey { get }
}

extension QueryField {
    public var path: [FieldKey] {
        [self.key]
    }
}
