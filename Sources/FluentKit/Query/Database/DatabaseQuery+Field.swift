extension DatabaseQuery {
    public enum Field {
        case path([FieldKey], schema: String)
        case extendedPath([FieldKey], schema: String, space: String?)
        case custom(Any)
    }
}

extension DatabaseQuery.Field: CustomStringConvertible {
    public var description: String {
        switch self {
        case .path(let path, let schema):
            return "\(schema)\(path)"
        case .extendedPath(let path, let schema, let space):
            return "\(space.map { "\($0)." } ?? "")\(schema)\(path)"
        case .custom(let custom):
            return "custom(\(custom))"
        }
    }
}
