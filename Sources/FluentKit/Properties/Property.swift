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
    func queryableValue() -> DatabaseQuery.Value?
}

public protocol QueryableProperty: AnyQueryableProperty, Property {
    static func queryValue(_ value: Value) -> DatabaseQuery.Value
}

extension AnyQueryableProperty where Self: QueryableProperty {
    public func queryableValue() -> DatabaseQuery.Value? {
        return self.value.map { Self.queryValue($0) }
    }
}

extension QueryableProperty {
    public static func queryValue(_ value: Value) -> DatabaseQuery.Value {
        .bind(value)
    }
}

/// A property which can be addressed as a single value by a query, even if an indirection through
/// a more convenient representation must be made to do so.
///
/// This protocol bridges the gap between `AnyQueryableProperty` - which describes a property whose
/// singular `Value` directly relates to the value stored in the database for that property - and
/// the concrete relations `Parent` and `OptionalParent`, for which the notions of equality and
/// identity are not interchangeable. Via `AnyQueryAddressableProperty`, both of these categories
/// may be handled dynamically, rather than special-casing on the behaviors of the relations.
///
/// In other words, to be "queryable" a property must be equatable, but to be "query-addressable",
/// it need only be identifiable. Any queryable property is automatically query-addressable, but
/// the reverse is not necessarily true.
public protocol AnyQueryAddressableProperty: AnyProperty {
    var anyQueryableProperty: AnyQueryableProperty { get }
    var queryablePath: [FieldKey] { get }
}

/// The type-bound version of `AnyQueryAddressableProperty`.
public protocol QueryAddressableProperty: AnyQueryAddressableProperty, Property {
    associatedtype QueryablePropertyType: QueryableProperty where QueryablePropertyType.Model == Self.Model
    var queryableProperty: QueryablePropertyType { get }
}
