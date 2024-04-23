import struct Foundation.Date
import struct Foundation.UUID

public struct DatabaseSchema: Sendable {
    public enum Action: Sendable {
        case create
        case update
        case delete
    }
    
    public indirect enum DataType: Sendable {
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
        
        public struct Enum: Sendable {
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
        case custom(any Sendable)
    }

    public enum FieldConstraint: Sendable {
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
        case custom(any Sendable)
    }

    public enum Constraint: Sendable {
        case constraint(ConstraintAlgorithm, name: String?)
        case custom(any Sendable)
    }
    
    public enum ConstraintAlgorithm: Sendable {
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
        case custom(any Sendable)
    }

    public enum ForeignKeyAction: Sendable {
        case noAction
        case restrict
        case cascade
        case setNull
        case setDefault
    }
    
    public enum FieldDefinition: Sendable {
        case definition(
            name: FieldName,
            dataType: DataType,
            constraints: [FieldConstraint]
        )
        case custom(any Sendable)
    }

    public enum FieldUpdate: Sendable {
        case dataType(name: FieldName, dataType: DataType)
        case custom(any Sendable)
    }
    
    public enum FieldName: Sendable {
        case key(FieldKey)
        case custom(any Sendable)
    }

    public enum ConstraintDelete: Sendable {
        case constraint(ConstraintAlgorithm)
        case name(String)
        case custom(any Sendable)
        
        /// Deletion specifier for an explicitly-named constraint known to be a referential constraint.
        /// 
        /// Certain old versions of certain databases (I'm looking at you, MySQL 5.7...) do not support dropping
        /// a `FOREIGN KEY` constraint by name without knowing ahead of time that it is a foreign key. When an
        /// unfortunate user runs into this, the options are:
        ///
        /// - Trap the resulting error and retry. This is exceptionally awkward to handle automatically, and can
        ///   lead to retry loops if multiple deletions are specified in a single operation.
        /// - Force the user to issue a raw SQL query instead. This is obviously undesirable.
        /// - Force an upgrade of the underlying database. No one should be using MySQL 5.7 anymore, but Fluent
        ///   recognizes that this isn't always under the user's control.
        /// - Require the user to specify the deletion with ``constraint(_:)``, providing the complete, accurate,
        ///   and current definition of the foreign key. This is information the user may not even know, and
        ///   certainly should not be forced to repeat here.
        /// - Provide a means for the user to specify that a given constraint to be deleted by name is known to be
        ///   a foreign key. For databases which _don't_ suffer from this particular syntactical issue (so, almost
        ///   everything), this is exactly the same as specifying ``name(_:)``.
        ///
        /// In short, this is the marginal best choice from a list of really bad choices - an ugly, backhanded
        /// workaround for MySQL 5.7 users.
        ///
        /// > Note: A static method is provided rather than a new `enum` case because adding new cases to a public
        /// > enum without library evolution enabled (which only the stdlib can do) is a source compatibility break
        /// > and requires a `semver-major` version bump. This rule is often ignored, but ignoring it doesn't make
        /// > the problem moot.
        public static func namedForeignKey(_ name: String) -> ConstraintDelete {
            self.custom(_ForeignKeyByNameExtension(name: name))
        }
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

extension DatabaseSchema.ConstraintDelete {
    /// For internal use only.
    ///
    /// Do not use this type directly; it's only public because FluentSQL needs to be able to get at it.
    /// The use of `@_spi` will be replaced with the `package` modifier once a suitable minimum version
    /// of Swift becomes required.
    @_spi(FluentSQLSPI)
    public/*package*/ struct _ForeignKeyByNameExtension: Sendable {
        public/*package*/ let name: String
    }
}
