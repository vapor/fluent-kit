extension DatabaseQuery {
    public enum Limit {
        case count(Int)
        case custom(Any)
    }

    public enum Offset {
        case count(Int)
        case custom(Any)
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
