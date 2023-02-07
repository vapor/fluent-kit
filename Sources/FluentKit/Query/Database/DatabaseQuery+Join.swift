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
        
        case extendedJoin(
            schema: String,
            space: String?,
            alias: String?,
            Method,
            foreign: Field,
            local: Field
        )
        
        case advancedJoin(
            schema: String,
            space: String?,
            alias: String?,
            Method,
            filters: [Filter]
        )
        
        case custom(Any)
    }
}

extension DatabaseQuery.Join: CustomStringConvertible {
    public var description: String {
        switch self {
        case .join(let schema, let alias, let method, let foreign, let local):
            return "\(self.schemaDescription(schema: schema, alias: alias)) \(method) on \(foreign) == \(local)"

        case .extendedJoin(let schema, let space, let alias, let method, let foreign, let local):
            return "\(self.schemaDescription(space: space, schema: schema, alias: alias)) \(method) on \(foreign) == \(local)"

        case .advancedJoin(let schema, let space, let alias, let method, let filters):
            return "\(self.schemaDescription(space: space, schema: schema, alias: alias)) \(method) on \(filters)"

        case .custom(let custom):
            return "custom(\(custom))"
        }
    }
    
    private func schemaDescription(space: String? = nil, schema: String, alias: String?) -> String {
        [space, schema].compactMap({ $0 }).joined(separator: ".") + (alias.map { " as \($0)" } ?? "")
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
