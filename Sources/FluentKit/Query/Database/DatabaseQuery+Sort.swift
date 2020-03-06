extension DatabaseQuery {
    public enum Sort {
        public enum Direction {
            case ascending
            case descending
            case custom(Any)
        }
        case sort(Field, Direction)
        case custom(Any)
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
