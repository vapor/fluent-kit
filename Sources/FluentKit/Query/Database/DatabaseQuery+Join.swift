extension DatabaseQuery {
    public enum Join {
        public enum Method {
            case inner
            case left
            case custom(Any)
        }

        case join(
            schema: String,
            alias: String?,
            Method,
            foreign: Field,
            local: Field
        )
        case custom(Any)
    }
}

extension DatabaseQuery.Join: CustomStringConvertible {
    public var description: String {
        switch self {
        case .join(let schema, let alias, let method, let foreign, let local):
            let schemaString: String
            if let alias = alias {
                schemaString = "\(schema) as \(alias)"
            } else {
                schemaString = "\(schema)"
            }
            return "\(schemaString) \(method) on \(foreign) == \(local)"
        case .custom(let custom):
            return "custom(\(custom))"
        }
    }
}

extension DatabaseQuery.Join.Method: CustomStringConvertible {
    public var description: String {
        switch self {
        case .inner:
            return "inner"
        case .left:
            return "left"
        case .custom(let custom):
            return "custom(\(custom))"
        }
    }
}
