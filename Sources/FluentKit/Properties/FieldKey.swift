public indirect enum FieldKey {
    case id
    case string(String)
    case aggregate
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
        }
    }
}

extension FieldKey: Equatable { }

extension FieldKey: Hashable { }
