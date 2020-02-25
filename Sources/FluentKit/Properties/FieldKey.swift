public indirect enum FieldKey: Equatable, Hashable, ExpressibleByStringLiteral, CustomStringConvertible {
    case id
    case string(String)
    case prefixed(String, FieldKey)
    case aggregate

    public var description: String {
        switch self {
        case .id:
            return "id"
        case .string(let name):
            return name
        case .aggregate:
            return "aggregate"
        case .prefixed(let prefix, let key):
            return prefix + key.description
        }
    }

    public init(stringLiteral value: String) {
        switch value {
        case "id", "_id":
            self = .id
        default:
            self = .string(value)
        }
    }
}
