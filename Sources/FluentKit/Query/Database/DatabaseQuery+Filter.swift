extension DatabaseQuery {
    public enum Filter: Sendable {
        public enum Method: Sendable {
            public static var equal: Method {
                .equality(inverse: false)
            }

            public static var notEqual: Method {
                .equality(inverse: true)
            }

            public static var greaterThan: Method {
                .order(inverse: false, equality: false)
            }

            public static var greaterThanOrEqual: Method {
                .order(inverse: false, equality: true)
            }

            public static var lessThan: Method {
                .order(inverse: true, equality: false)
            }

            public static var lessThanOrEqual: Method {
                .order(inverse: true, equality: true)
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
            "\(field) \(method) \(value)"
        case .field(let fieldA, let method, let fieldB):
            "\(fieldA) \(method) \(fieldB)"
        case .group(let filters, let relation):
            filters.map { "(\($0))" }.joined(separator: " \(relation) ")
        case .custom(let any):
            "custom(\(any))"
        }
    }

    var describedByLoggingMetadata: Logger.MetadataValue {
        switch self {
        case .value(let field, let method, let value):
            ["field": field.describedByLoggingMetadata, "method": "\(method)", "value": value.describedByLoggingMetadata]
        case .field(let field, let method, let field2):
            ["field1": field.describedByLoggingMetadata, "method": "\(method)", "field2": field2.describedByLoggingMetadata]
        case .group(let array, let relation):
            ["group": .array(array.map(\.describedByLoggingMetadata)), "relation": "\(relation)"]
        case .custom:
            .stringConvertible(self)
        }
    }
}

extension DatabaseQuery.Filter.Method: CustomStringConvertible {
    public var description: String {
        switch self {
        case .equality(let inverse):
            inverse ? "!=" : "="
        case .order(let inverse, let equality):
            if equality {
                inverse ? "<=" : ">="
            } else {
                inverse ? "<" : ">"
            }
        case .subset(let inverse):
            inverse ? "!~~" : "~~"
        case .contains(let inverse, let contains):
            inverse ? "!\(contains)" : "\(contains)"
        case .custom(let any):
            "custom(\(any))"
        }
    }
}

extension DatabaseQuery.Filter.Method.Contains: CustomStringConvertible {
    public var description: String {
        switch self {
        case .prefix:
            "startswith"
        case .suffix:
            "endswith"
        case .anywhere:
            "contains"
        }
    }
}

extension DatabaseQuery.Filter.Relation: CustomStringConvertible {
    public var description: String {
        switch self {
        case .and:
            "and"
        case .or:
            "or"
        case .custom(let custom):
            "custom(\(custom))"
        }
    }
}
