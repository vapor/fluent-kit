extension DatabaseQuery {
    public enum Value {
        case bind(Encodable)
        case dictionary([FieldKey: Value])
        case array([Value])
        case null
        case enumCase(String)
        case `default`
        case custom(Any)
    }
}

extension DatabaseQuery.Value: CustomStringConvertible {
    public var description: String {
        switch self {
        case .bind(let encodable):
            if let convertible = encodable as? CustomDebugStringConvertible {
                return convertible.debugDescription
            } else {
                return "\(encodable)"
            }
        case .dictionary(let dictionary):
            return dictionary.description
        case .array(let array):
            return array.description
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
