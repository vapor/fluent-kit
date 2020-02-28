extension DatabaseQuery {
    public enum Field {
        case field(path: [FieldKey], schema: String)
        case custom(Any)
    }
}

extension DatabaseQuery.Field: CustomStringConvertible {
    public var description: String {
        switch self {
        case .field(let field, let schema):
            return "\(schema).\(field)"
        case .custom(let custom):
            return "custom(\(custom))"
        }
    }
}
