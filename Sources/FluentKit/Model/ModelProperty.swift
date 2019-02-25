public protocol ModelProperty {
    var name: String { get }
    var type: Any.Type { get }
    var dataType: DatabaseSchema.DataType? { get }
    var constraints: [DatabaseSchema.FieldConstraint] { get }
    func encode(to container: inout KeyedEncodingContainer<StringCodingKey>) throws
    func decode(from container: KeyedDecodingContainer<StringCodingKey>) throws
}
