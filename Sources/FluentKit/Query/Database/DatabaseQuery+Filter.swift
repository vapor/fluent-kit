extension DatabaseQuery {
    public enum Filter: Sendable {
        public enum Method: Sendable {
            public static var equal: Method {
                return .equality(inverse: false)
            }

            public static var notEqual: Method {
                return .equality(inverse: true)
            }

            public static var greaterThan: Method {
                return .order(inverse: false, equality: false)
            }

            public static var greaterThanOrEqual: Method {
                return .order(inverse: false, equality: true)
            }

            public static var lessThan: Method {
                return .order(inverse: true, equality: false)
            }

            public static var lessThanOrEqual: Method {
                return .order(inverse: true, equality: true)
            }

            /// LHS is equal/not equal to RHS
            case equality(inverse: Bool)

            /// LHS is greater/less than [or equal to] RHS
            case order(inverse: Bool, equality: Bool)

            /// LHS exists in/doesn't exist in RHS
            case subset(inverse: Bool)

            public enum Contains: Sendable {
                case prefix
                case suffix
                case anywhere
            }
            
            /// RHS is [anchored] substring/isn't [anchored] substring of LHS
            case contains(inverse: Bool, Contains)

            /// Custom method
            case custom(any Sendable)
        }

        public enum Relation: Sendable {
            case and
            case or
            case custom(any Sendable)
        }

        case value(Field, Method, Value)
        case field(Field, Method, Field)
        case group([Filter], Relation)
        case custom(any Sendable)
    }
}

extension DatabaseQuery.Filter: CustomStringConvertible {
    public var description: String {
        switch self {
        case .value(let field, let method, let value):
            return "\(field) \(method) \(value)"
        case .field(let fieldA, let method, let fieldB):
            return "\(fieldA) \(method) \(fieldB)"
        case .group(let filters, let relation):
            return filters.map { "(\($0))" }.joined(separator: " \(relation) ")
        case .custom(let any):
            return "custom(\(any))"
        }
    }

    var describedByLoggingMetadata: Logger.MetadataValue {
        switch self {
        case .value(let field, let method, let value):
            return ["field": field.describedByLoggingMetadata, "method": "\(method)", "value": value.describedByLoggingMetadata]
        case .field(let field, let method, let field2):
            return ["field1": field.describedByLoggingMetadata, "method": "\(method)", "field2": field2.describedByLoggingMetadata]
        case .group(let array, let relation):
            return ["group": .array(array.map(\.describedByLoggingMetadata)), "relation": "\(relation)"]
        case .custom:
            return .stringConvertible(self)
        }
    }
}

extension DatabaseQuery.Filter.Method: CustomStringConvertible {
    public var description: String {
        switch self {
        case .equality(let inverse):
            return inverse ? "!=" : "="
        case .order(let inverse, let equality):
            if equality {
                return inverse ? "<=" : ">="
            } else {
                return inverse ? "<" : ">"
            }
        case .subset(let inverse):
            return inverse ? "!~~" : "~~"
        case .contains(let inverse, let contains):
            return inverse ? "!\(contains)" : "\(contains)"
        case .custom(let any):
            return "custom(\(any))"
        }
    }
}

extension DatabaseQuery.Filter.Method.Contains: CustomStringConvertible {
    public var description: String {
        switch self {
        case .prefix:
            return "startswith"
        case .suffix:
            return "endswith"
        case .anywhere:
            return "contains"
        }
    }
}

extension DatabaseQuery.Filter.Relation: CustomStringConvertible {
    public var description: String {
        switch self {
        case .and:
            return "and"
        case .or:
            return "or"
        case .custom(let custom):
            return "custom(\(custom))"
        }
    }
}
