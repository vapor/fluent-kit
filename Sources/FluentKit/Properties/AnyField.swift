public protocol PropertyProtocol: AnyProperty {
    associatedtype Model: Fields
    associatedtype Value: Codable
    var value: Value? { get set }
}

public protocol FieldProtocol: PropertyProtocol { }

public protocol AnyProperty: class {
    static var anyValueType: Any.Type { get }
    var anyValue: Any? { get }

    var path: [FieldKey] { get }
    var nested: [AnyProperty] { get }

    func input(to input: inout DatabaseInput)
    func output(from output: DatabaseOutput) throws
    func encode(to encoder: Encoder) throws
    func decode(from decoder: Decoder) throws
}

extension AnyProperty where Self: PropertyProtocol {
    public var anyValue: Any? {
        self.value
    }

    public static var anyValueType: Any.Type {
        Value.self
    }
}

public protocol AnyField { }
