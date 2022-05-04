extension DatabaseQuery {
    public enum Action {
        public enum ReadIntent {
            case readOnly
            case update
            case share
        }

        case create
        case read(ReadIntent)
        case update
        case delete
        case aggregate(Aggregate)
        case custom(Any)
    }
}

extension DatabaseQuery.Action: CustomStringConvertible {
    public var description: String {
        switch self {
        case .create:
            return "create"
        case let .read(intent):
            return "read (\(intent))"
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

extension DatabaseQuery.Action.ReadIntent: CustomStringConvertible {
    public var description: String {
        switch self {
        case .readOnly:
            return "read-only"
        case .update:
            return "for update"
        case .share:
            return "for share"
        }
    }
}
