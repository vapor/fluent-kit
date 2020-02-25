extension DatabaseQuery {
    public enum Aggregate {
        public enum Method {
            case count
            case sum
            case average
            case minimum
            case maximum
            case custom(Any)
        }
        case field(Field, Method)
        case custom(Any)
    }
}

extension DatabaseQuery.Aggregate: CustomStringConvertible {
    public var description: String {
        switch self {
        case .field(let field, let method):
            return "\(method)(\(field))"
        case .custom(let custom):
            return "custom(\(custom))"
        }
    }
}

extension DatabaseQuery.Aggregate.Method: CustomStringConvertible {
    public var description: String {
        switch self {
        case .count:
            return "count"
        case .sum:
            return "sum"
        case .average:
            return "average"
        case .minimum:
            return "minimum"
        case .maximum:
            return "maximum"
        case .custom(let custom):
            return "custom(\(custom))"
        }
    }
}
