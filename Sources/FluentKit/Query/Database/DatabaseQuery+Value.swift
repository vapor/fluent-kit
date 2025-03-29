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
                String(reflecting: convertible)
            } else {
                String(describing: encodable)
            }
        case .dictionary(let dictionary):
            String(describing: dictionary)
        case .array(let array):
            String(describing: array)
        case .enumCase(let string):
            string
        case .null:
            "nil"
        case .default:
            "default"
        case .custom(let custom):
            "custom(\(custom))"
        }
    }

    var describedByLoggingMetadata: Logger.MetadataValue {
        switch self {
        case .dictionary(let d):
            .dictionary(.init(uniqueKeysWithValues: d.map { ($0.description, $1.describedByLoggingMetadata) }))
        case .array(let a):
            .array(a.map(\.describedByLoggingMetadata))
        default:
            .stringConvertible(self)
        }
    }

}
