extension DatabaseQuery {
    public enum Sort: Sendable {
        public enum Direction: Sendable {
            case ascending
            case descending
            case custom(any Sendable)
        }
        case sort(Field, Direction)
        case custom(any Sendable)
    }
}

extension DatabaseQuery.Sort: CustomStringConvertible {
    public var description: String {
        switch self {
        case .sort(let field, let direction):
            "\(field) \(direction)"
        case .custom(let custom):
            "custom(\(custom))"
        }
    }

    var describedByLoggingMetadata: Logger.MetadataValue {
        switch self {
        case .sort(let field, let direction):
            ["field": field.describedByLoggingMetadata, "direction": "\(direction)"]
        case .custom:
            .stringConvertible(self)
        }
    }
}

extension DatabaseQuery.Sort.Direction: CustomStringConvertible {
    public var description: String {
        switch self {
        case .ascending:
            "ascending"
        case .descending:
            "descending"
        case .custom(let custom):
            "custom(\(custom))"
        }
    }
}
