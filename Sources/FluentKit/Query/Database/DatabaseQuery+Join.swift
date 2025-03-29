extension DatabaseQuery {
    public enum Join: Sendable {
        public enum Method: Sendable {
            case inner
            case left
            case custom(any Sendable)
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
        
        case custom(any Sendable)
    }
}

extension DatabaseQuery.Join: CustomStringConvertible {
    public var description: String {
        switch self {
        case .join(let schema, let alias, let method, let foreign, let local):
            "\(self.schemaDescription(schema: schema, alias: alias)) \(method) on \(foreign) == \(local)"

        case .extendedJoin(let schema, let space, let alias, let method, let foreign, let local):
            "\(self.schemaDescription(space: space, schema: schema, alias: alias)) \(method) on \(foreign) == \(local)"

        case .advancedJoin(let schema, let space, let alias, let method, let filters):
            "\(self.schemaDescription(space: space, schema: schema, alias: alias)) \(method) on \(filters)"

        case .custom(let custom):
            "custom(\(custom))"
        }
    }

    var describedByLoggingMetadata: Logger.MetadataValue {
        switch self {
        case .join(let schema, let alias, let method, let foreign, let local):
            .dictionary([
                "schema": "\(schema)", "alias": alias.map { "\($0)" }, "method": "\(method)",
                "foreign": foreign.describedByLoggingMetadata, "local": local.describedByLoggingMetadata
            ].compactMapValues { $0 })
        case .extendedJoin(let schema, let space, let alias, let method, let foreign, let local):
            .dictionary([
                "schema": "\(schema)", "space": space.map { "\($0)" }, "alias": alias.map { "\($0)" }, "method": "\(method)",
                "foreign": foreign.describedByLoggingMetadata, "local": local.describedByLoggingMetadata
            ].compactMapValues { $0 })
        case .advancedJoin(let schema, let space, let alias, let method, let filters):
            .dictionary([
                "schema": "\(schema)", "space": space.map { "\($0)" }, "alias": alias.map { "\($0)" }, "method": "\(method)",
                "filters": .array(filters.map(\.describedByLoggingMetadata))
            ].compactMapValues { $0 })
        case .custom:
            .stringConvertible(self)
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
            "inner"
        case .left:
            "left"
        case .custom(let custom):
            "custom(\(custom))"
        }
    }
}
