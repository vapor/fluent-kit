extension DatabaseQuery {

    public struct ConflictResolutionStrategy {
        public var targets: [Field]
        public var action: ConflictAction

        public enum ConflictAction {
            case ignore
            case update([FieldKey: Value])
        }
    }
}

extension DatabaseQuery.ConflictResolutionStrategy: CustomStringConvertible {
    public var description: String {
        "on \(targets) \(action)"
    }
}


extension DatabaseQuery.ConflictResolutionStrategy.ConflictAction: CustomStringConvertible {
    public var description: String {
        switch self {
        case .ignore:
            return "ignore"
        case .update(let values):
            return "update \(values)"
        }
    }
}
