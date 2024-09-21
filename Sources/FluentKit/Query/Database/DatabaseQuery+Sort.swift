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
            return "\(field) \(direction)"
        case .custom(let custom):
            return "custom(\(custom))"
        }
    }

    var describedByLoggingMetadata: Logger.MetadataValue {
        switch self {
        case .sort(let field, let direction):
            return ["field": field.describedByLoggingMetadata, "direction": "\(direction)"]
        case .custom:
            return .stringConvertible(self)
        }
    }
}

extension DatabaseQuery.Sort.Direction: CustomStringConvertible {
    public var description: String {
        switch self {
        case .ascending:
            return "ascending"
        case .descending:
            return "descending"
        case .custom(let custom):
            return "custom(\(custom))"
        }
    }
}
