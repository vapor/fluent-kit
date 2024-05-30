extension DatabaseQuery {
    public enum Field: Sendable {
        case path([FieldKey], schema: String)
        case extendedPath([FieldKey], schema: String, space: String?)
        case custom(any Sendable)
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

    var describedByLoggingMetadata: Logger.MetadataValue {
        switch self {
        case .path(let array, let schema):
            return "\(schema).\(array.map(\.description).joined(separator: "->"))"
        case .extendedPath(let array, let schema, let space):
            return "\(space.map { "\($0)." } ?? "")\(schema).\(array.map(\.description).joined(separator: "->"))"
        case .custom:
            return .stringConvertible(self)
        }
    }
}
