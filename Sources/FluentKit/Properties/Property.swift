public protocol AnyValue: class {
    static var anyValueType: Any.Type { get }
    var anyValue: Any? { get }
}

public protocol ValueProtocol: AnyValue {
    associatedtype Model: Fields
    associatedtype Value: Codable
    var value: Value? { get set }
}

extension AnyValue where Self: ValueProtocol {
    public var anyValue: Any? {
        self.value
    }

    public static var anyValueType: Any.Type {
        Value.self
    }
}

public protocol AnyProperty: AnyValue {
    var keys: [FieldKey] { get }
    func input(to input: inout DatabaseInput)
    func output(from output: DatabaseOutput) throws
    func encode(to encoder: Encoder) throws
    func decode(from decoder: Decoder) throws
}

public protocol PropertyProtocol: AnyProperty, ValueProtocol { }

public protocol AnyField {
    var key: FieldKey { get }
    var path: [FieldKey] { get }
}

extension AnyField {
    public var path: [FieldKey] {
        []
    }
}

public protocol FieldProtocol: AnyField, ValueProtocol {
    /// Get the given Value in a form suitable for queries.
    /// Most values can be bound to queries, but some need
    /// to be inserted statically.
    static func queryValue(_ value: Value) -> DatabaseQuery.Value
}

extension FieldProtocol {
    public static func queryValue(_ value: Value) -> DatabaseQuery.Value {
        .bind(value)
    }
}
