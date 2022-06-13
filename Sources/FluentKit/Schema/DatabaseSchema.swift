import struct Foundation.Date
import struct Foundation.UUID

public struct DatabaseSchema {
    public enum Action {
        case create
        case update
        case delete
    }
    
    public indirect enum DataType {
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

            public init(name: String, cases: [String]) {
                self.name = name
                self.cases = cases
            }
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

        public static var json: DataType {
            .dictionary
        }
        public static var dictionary: DataType {
            .dictionary(of: nil)
        }
        case dictionary(of: DataType?)

        public static var array: DataType {
            .array(of: nil)
        }
        case array(of: DataType?)
        case custom(Any)
    }

    public enum FieldConstraint {
        public static func references(
            _ schema: String,
            space: String? = nil,
            _ field: FieldKey,
            onDelete: ForeignKeyAction = .noAction,
            onUpdate: ForeignKeyAction = .noAction
        ) -> Self {
            .foreignKey(
                schema,
                space: space,
                .key(field),
                onDelete: onDelete,
                onUpdate: onUpdate
            )
        }

        case required
        case identifier(auto: Bool)
        case foreignKey(
            _ schema: String,
            space: String? = nil,
            _ field: FieldName,
            onDelete: ForeignKeyAction,
            onUpdate: ForeignKeyAction
        )
        case custom(Any)
    }

    public enum Constraint {
        case constraint(ConstraintAlgorithm, name: String?)
        case custom(Any)
    }
    
    public enum ConstraintAlgorithm {
        case unique(fields: [FieldName])
        case foreignKey(
            _ fields: [FieldName],
            _ schema: String,
            space: String? = nil,
            _ foreign: [FieldName],
            onDelete: ForeignKeyAction,
            onUpdate: ForeignKeyAction
        )
        case compositeIdentifier(_ fields: [FieldName])
        case custom(Any)
    }

    public enum ForeignKeyAction {
        case noAction
        case restrict
        case cascade
        case setNull
        case setDefault
    }
    
    public enum FieldDefinition {
        case definition(
            name: FieldName,
            dataType: DataType,
            constraints: [FieldConstraint]
        )
        case custom(Any)
    }

    public enum FieldUpdate {
        case dataType(name: FieldName, dataType: DataType)
        case custom(Any)
    }
    
    public enum FieldName {
        case key(FieldKey)
        case custom(Any)
    }

    public enum ConstraintDelete {
        case constraint(ConstraintAlgorithm)
        case name(String)
        case custom(Any)
    }

    public var action: Action
    public var schema: String
    public var space: String?
    public var createFields: [FieldDefinition]
    public var updateFields: [FieldUpdate]
    public var deleteFields: [FieldName]
    public var createConstraints: [Constraint]
    public var deleteConstraints: [ConstraintDelete]
    public var exclusiveCreate: Bool
    
    public init(schema: String, space: String? = nil) {
        self.action = .create
        self.schema = schema
        self.space = space
        self.createFields = []
        self.updateFields = []
        self.deleteFields = []
        self.createConstraints = []
        self.deleteConstraints = []
        self.exclusiveCreate = true
    }
}
