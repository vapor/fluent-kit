public struct NestedPath: ExpressibleByStringLiteral {
    public var path: [String]
    public init(path: [String]) {
        self.path = path
    }
    public init(stringLiteral value: String) {
        self.path = value.split(separator: ".").map(String.init)
    }
    
}
extension QueryBuilder {
    public func filter<Value, NestedValue>(
        _ field: KeyPath<Model, Field<Value>>,
        _ path: NestedPath,
        _ method: DatabaseQuery.Filter.Method,
        _ value: NestedValue
    ) -> Self
        where Value: Codable, NestedValue: Codable
    {
        return self.filter(Model.shared[keyPath: field].name, path, method, value)
    }

    public func filter<NestedValue>(
        _ fieldName: String,
        _ path: NestedPath,
        _ method: DatabaseQuery.Filter.Method,
        _ value: NestedValue
    ) -> Self
        where NestedValue: Codable
    {
        let field: DatabaseQuery.Field = .field(path: [fieldName] + path.path, entity: Model.entity, alias: nil)
        return self.filter(field, method, .bind(value))
    }
}
