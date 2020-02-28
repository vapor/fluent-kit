extension DatabaseQuery {
    public enum Field {
        case path([FieldKey], schema: String)
        case custom(Any)
    }
}

extension DatabaseQuery.Field: CustomStringConvertible {
    public var description: String {
        switch self {
        case .path(let path, let schema):
            return "\(schema)\(path)"
        case .custom(let custom):
            return "custom(\(custom))"
        }
    }
}
