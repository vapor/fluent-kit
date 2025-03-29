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
            "create"
        case .read:
            "read"
        case .update:
            "update"
        case .delete:
            "delete"
        case .aggregate(let aggregate):
            "aggregate(\(aggregate))"
        case .custom(let custom):
            "custom(\(custom))"
        }
    }
}
