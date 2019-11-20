import struct Foundation.Date
import struct Foundation.UUID

private protocol _OptionalType {
    static var _wrappedType: Any.Type { get }
}

extension Optional: _OptionalType {
    static var _wrappedType: Any.Type {
        return Wrapped.self
    }
}

public struct DatabaseSchema {
    public enum Action {
        case create
        case update
        case delete
    }
    
    public enum DataType {
        static func bestFor(type: Any.Type) -> DataType {
            if let optional = type as? _OptionalType.Type {
                return self.bestFor(type: optional._wrappedType)
            }

            func id(_ type: Any.Type) -> ObjectIdentifier {
                return ObjectIdentifier(type)
            }
            
            switch id(type) {
            case id(String.self): return .string
            case id(Int.self), id(Int64.self): return .int64
            case id(UInt.self), id(UInt64.self): return .uint64
            case id(UUID.self): return .uuid
            case id(Date.self): return .datetime
            case id(Bool.self): return .bool
            default: return .json
            }
        }
        
        case json
        
        public static var int: DataType {
            return .int64
        }
        case int8
        case int16
        case int32
        case int64
        
        public static var uint: DataType {
            return .uint64
        }
        case uint8
        case uint16
        case uint32
        case uint64
        
        
        case bool
        
        public struct Enum {
            public var name: String
            public var cases: [String]
        }
        case `enum`(Enum)
        case string
        
        case time
        case date
        case datetime
        
        case float
        case double
        case data
        case uuid
        case custom(Any)
    }
    
    public enum FieldConstraint {
        case required
        case identifier(auto: Bool)
        case foreignKey(field: ForeignFieldName, onDelete: Constraint.ForeignKeyAction, onUpdate: Constraint.ForeignKeyAction)
        case custom(Any)
    }
    
    public enum Constraint {
        case unique(fields: [FieldName])
        case foreignKey(fields: [FieldName], foreignSchema: String, foreignFields: [FieldName], onDelete: ForeignKeyAction, onUpdate: ForeignKeyAction)
        case custom(Any)

        public enum ForeignKeyAction {
            case noAction
            case restrict
            case cascade
            case setNull
            case setDefault
        }
    }
    
    public enum FieldDefinition {
        case definition(name: FieldName, dataType: DataType, constraints: [FieldConstraint])
        case custom(Any)
    }
    
    public enum FieldName {
        case string(String)
        case custom(Any)
    }

    public enum ForeignFieldName {
        case string(schema: String, field: String)
        case custom(schema: Any, field: Any)
    }

    public var action: Action
    public var schema: String
    public var createFields: [FieldDefinition]
    public var deleteFields: [FieldName]
    public var constraints: [Constraint]
    
    public init(schema: String) {
        self.action = .create
        self.schema = schema
        self.createFields = []
        self.deleteFields = []
        self.constraints = []
    }
}
