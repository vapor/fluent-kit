extension DatabaseQuery {
    public enum Limit: Sendable {
        case count(Int)
        case custom(any Sendable)
    }

    public enum Offset: Sendable {
        case count(Int)
        case custom(any Sendable)
    }
}

extension DatabaseQuery.Limit: CustomStringConvertible {
    public var description: String {
        switch self {
        case .count(let count):
            return "count(\(count))"
        case .custom(let custom):
            return "custom(\(custom))"
        }
    }
}

extension DatabaseQuery.Offset: CustomStringConvertible {
    public var description: String {
        switch self {
        case .count(let count):
            return "count(\(count))"
        case .custom(let custom):
            return "custom(\(custom))"
        }
    }
}
