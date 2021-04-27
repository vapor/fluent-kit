public protocol AnyProperty: AnyObject {
    static var anyValueType: Any.Type { get }
    var anyValue: Any? { get }
}

public protocol Property: AnyProperty {
    associatedtype Model: Fields
    associatedtype Value: Codable
    var value: Value? { get set }
}

extension AnyProperty where Self: Property {
    public var anyValue: Any? {
        self.value
    }

    public static var anyValueType: Any.Type {
        Value.self
    }
}

public protocol AnyDatabaseProperty: AnyProperty {
    var keys: [FieldKey] { get }
    func input(to input: DatabaseInput)
    func output(from output: DatabaseOutput) throws
}

public protocol AnyCodableProperty: AnyProperty {
    func encode(to encoder: Encoder) throws
    func decode(from decoder: Decoder) throws
}

public protocol AnyQueryableProperty: AnyProperty {
    var path: [FieldKey] { get }
}

public protocol QueryableProperty: AnyQueryableProperty, Property {
    static func queryValue(_ value: Value) -> DatabaseQuery.Value
}

extension QueryableProperty {
    public static func queryValue(_ value: Value) -> DatabaseQuery.Value {
        .bind(value)
    }
}
