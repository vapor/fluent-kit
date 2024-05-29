extension DatabaseQuery {
    public enum Value: Sendable {
        case bind(any Encodable & Sendable)
        case dictionary([FieldKey: Value])
        case array([Value])
        case null
        case enumCase(String)
        case `default`
        case custom(any Sendable)
    }
}

extension DatabaseQuery.Value: CustomStringConvertible {
    public var description: String {
        switch self {
        case .bind(let encodable):
            if let convertible = encodable as? any CustomDebugStringConvertible {
                return String(reflecting: convertible)
            } else {
                return String(describing: encodable)
            }
        case .dictionary(let dictionary):
            return String(describing: dictionary)
        case .array(let array):
            return String(describing: array)
        case .enumCase(let string):
            return string
        case .null:
            return "nil"
        case .default:
            return "default"
        case .custom(let custom):
            return "custom(\(custom))"
        }
    }
}
