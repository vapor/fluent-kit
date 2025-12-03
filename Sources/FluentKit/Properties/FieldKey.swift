public indirect enum FieldKey: Sendable {
    case id
    case string(String)
    case aggregate
    case prefix(FieldKey, FieldKey)
}

extension FieldKey: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        switch value {
        case "id", "_id":
            self = .id
        default:
            self = .string(value)
        }
    }
}

extension FieldKey: CustomStringConvertible {
    public var description: String {
        switch self {
        case .id:
            "id"
        case .string(let name):
            name
        case .aggregate:
            "aggregate"
        case .prefix(let prefix, let key):
            prefix.description + key.description
        }
    }
}

extension FieldKey: Equatable {}

extension FieldKey: Hashable {}
