public protocol FilterField {
    associatedtype Model: Fields
    associatedtype Value: Codable
    var path: [FieldKey] { get }
    var wrappedValue: Value { get }
}

public protocol QueryField: FilterField {
    var key: FieldKey { get }
}
