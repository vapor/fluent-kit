extension DatabaseQuery {
    public enum Filter {
        public enum Method {
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

            /// LHS is equal to RHS
            case equality(inverse: Bool)

            /// LHS is greater than RHS
            case order(inverse: Bool, equality: Bool)

            /// LHS exists in RHS
            case subset(inverse: Bool)

            public enum Contains {
                case prefix
                case suffix
                case anywhere
            }
            
            /// RHS exists in LHS
            case contains(inverse: Bool, Contains)

            /// Custom method
            case custom(Any)
        }

        public enum Relation {
            case and
            case or
            case custom(Any)
        }

        case value(Field, Method, Value)
        case field(Field, Method, Field)
        case group([Filter], Relation)
        case custom(Any)
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
            return "\(relation) \(filters)"
        case .custom(let any):
            return "custom(\(any))"
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
            return (inverse ? "!" : "") + "\(contains)"
        case .custom(let any):
            return "custom(\(any))"
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
