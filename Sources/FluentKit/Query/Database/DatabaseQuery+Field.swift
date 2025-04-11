import Logging

extension DatabaseQuery {
    public enum Field: Sendable {
        case path([FieldKey], schema: String, space: String?)
        case custom(any Sendable)
    }
}

extension DatabaseQuery.Field: CustomStringConvertible {
    public var description: String {
        switch self {
        case .path(let path, let schema, let space):
            "\(space.map { "\($0)." } ?? "")\(schema)\(path)"
        case .custom(let custom):
            "custom(\(custom))"
        }
    }

    var describedByLoggingMetadata: Logger.MetadataValue {
        switch self {
        case .path(let array, let schema, let space):
            "\(space.map { "\($0)." } ?? "")\(schema).\(array.map(\.description).joined(separator: "->"))"
        case .custom:
            .stringConvertible(self)
        }
    }
}
