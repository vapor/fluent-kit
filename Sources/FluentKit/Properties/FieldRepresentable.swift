public protocol FieldRepresentable {
    associatedtype Model: Fields
    associatedtype Value: Codable
    var path: [FieldKey] { get }
    var wrappedValue: Value { get }
}
