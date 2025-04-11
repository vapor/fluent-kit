extension DatabaseQuery {
    public enum Aggregate: Sendable {
        public enum Method: Sendable {
            case count
            case sum
            case average
            case minimum
            case maximum
            case custom(any Sendable)
        }
        case field(Field, Method)
        case custom(any Sendable)
    }
}

extension DatabaseQuery.Aggregate: CustomStringConvertible {
    public var description: String {
        switch self {
        case .field(let field, let method):
            "\(method)(\(field))"
        case .custom(let custom):
            "custom(\(custom))"
        }
    }
}

extension DatabaseQuery.Aggregate.Method: CustomStringConvertible {
    public var description: String {
        switch self {
        case .count:
            "count"
        case .sum:
            "sum"
        case .average:
            "average"
        case .minimum:
            "minimum"
        case .maximum:
            "maximum"
        case .custom(let custom):
            "custom(\(custom))"
        }
    }
}
