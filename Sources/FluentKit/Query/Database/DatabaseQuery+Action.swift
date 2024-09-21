extension DatabaseQuery {
    public enum Action: Sendable {
        case create
        case read
        case update
        case delete
        case aggregate(Aggregate)
        case custom(any Sendable)
    }
}

extension DatabaseQuery.Action: CustomStringConvertible {
    public var description: String {
        switch self {
        case .create:
            return "create"
        case .read:
            return "read"
        case .update:
            return "update"
        case .delete:
            return "delete"
        case .aggregate(let aggregate):
            return "aggregate(\(aggregate))"
        case .custom(let custom):
            return "custom(\(custom))"
        }
    }
}
