public struct DatabaseQuery: CustomStringConvertible {
    public enum Action {
        case create
        case read
        case update
        case delete
        case custom(Any)
    }

    public enum Schema {
        case schema(name: String, alias: String?)
        case custom(Any)
    }
    
    public enum Field: CustomStringConvertible {
        public enum Aggregate: CustomStringConvertible {
            public enum Method {
                case count
                case sum
                case average
                case minimum
                case maximum
                case custom(Any)
            }
            
            public var description: String {
                switch self {
                case .custom(let custom):
                    return "\(custom)"
                case .fields(let method, let fields):
                    return "\(method)(\(fields))"
                }
            }
            
            case fields(method: Method, fields: [Field])
            case custom(Any)
        }
        
        public var description: String {
            switch self {
            case .aggregate(let aggregate):
                return aggregate.description
            case .field(let path, let schema, let alias):
                var description = path.joined(separator: ".")
                if let schema = schema {
                    description = schema + "." + description
                }
                if let alias = alias {
                    description = description + " as " + alias
                }
                return description
            case .custom(let custom):
                return "\(custom)"
            }
        }
        
        case aggregate(Aggregate)
        case field(path: [String], schema: String?, alias: String?)
        case custom(Any)
    }
    
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
    
    public enum Value: CustomStringConvertible {
        case bind(Encodable)
        case dictionary([String: Value])
        case array([Value])
        case null
        case `default`
        case custom(Any)

        public var description: String {
            switch self {
            case .bind(let encodable):
                if let convertible = encodable as? CustomDebugStringConvertible {
                    return convertible.debugDescription
                } else {
                    return "\(encodable)"
                }
            case .dictionary(let dictionary):
                return dictionary.description
            case .array(let array):
                return array.description
            case .null:
                return "nil"
            case .default:
                return "<default>"
            case .custom(let custom):
                return "\(custom)"
            }
        }
    }
    
    public enum Join {
        public enum Method {
            case inner, left, right, outer
            case custom(Any)
        }
        case join(schema: Schema, foreign: Field, local: Field, method: Method)
        case custom(Any)
    }

    public enum Sort {
        public enum Direction {
            case ascending
            case descending
            case custom(Any)
        }
        
        case sort(field: Field, direction: Direction)
        case custom(Any)
    }

    public enum Limit {
        case count(Int)
        case custom(Any)
    }

    public enum Offset {
        case count(Int)
        case custom(Any)
    }
    
    public var fields: [Field]
    public var action: Action
    public var filters: [Filter]
    public var input: [[Value]]
    public var joins: [Join]
    public var sorts: [Sort]
    public var limits: [Limit]
    public var offsets: [Offset]
    public var schema: String
    
    public var description: String {
        var parts = [
            "\(self.action)",
            self.schema
        ]
        if !self.fields.isEmpty {
            parts.append("fields=\(self.fields)")
        }
        if !self.filters.isEmpty {
            parts.append("filters=\(self.filters)")
        }
        return parts.joined(separator: " ")
    }

    init(schema: String) {
        self.schema = schema
        self.fields = []
        self.action = .read
        self.filters = []
        self.input = []
        self.joins = []
        self.sorts = []
        self.limits = []
        self.offsets = []
    }
}
