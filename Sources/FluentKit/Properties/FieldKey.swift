public indirect enum FieldKey {
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
            return "id"
        case .string(let name):
            return name
        case .aggregate:
            return "aggregate"
        case .prefix(let prefix, let key):
            return prefix.description + key.description
        }
    }
}

extension FieldKey: Equatable { }

extension FieldKey: Hashable { }
