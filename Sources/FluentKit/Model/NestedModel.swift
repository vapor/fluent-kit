public protocol FieldGroup: class, Codable {
    init()
}
extension FieldGroup {
    public typealias Field<Value> = ModelField<Self, Value>
        where Value: Codable
    
    public static func key<Field>(for field: KeyPath<Self, Field>) -> String
        where Field: FieldRepresentable
    {
        return Self.init()[keyPath: field].field.key
    }
}
