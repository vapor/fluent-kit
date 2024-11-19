extension DatabaseQuery {
    public enum Action: Sendable, Equatable {
        
        public static func == (lhs: DatabaseQuery.Action, rhs: DatabaseQuery.Action) -> Bool {
            switch (lhs, rhs) {
            case (.create, .create),
                (.read, .read),
                (.update, .update),
                (.delete, .delete):
                return true
            case let (.aggregate(lhs), .aggregate(rhs)):
                guard type(of: lhs) == type(of: rhs) else { return false }
                return String(describing: lhs) == String(describing: rhs)
            case let (.custom(lhs), .custom(rhs)):
                guard type(of: lhs) == type(of: rhs) else { return false }
                return String(describing: lhs) == String(describing: rhs)
            default:
                return false
            }
        }
        
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
