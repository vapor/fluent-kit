import SQLKit
import FluentKit

public protocol SQLConverterDelegate {
    func customDataType(_ dataType: DatabaseSchema.DataType) -> (any SQLExpression)?
    func nestedFieldExpression(_ column: String, _ path: [String]) -> any SQLExpression
    func beforeConvert(_ schema: DatabaseSchema) -> DatabaseSchema
}

extension SQLConverterDelegate {
    public func nestedFieldExpression(_ column: String, _ path: [String]) -> any SQLExpression {
        SQLNestedSubpathExpression(column: column, path: path)
    }
    
    public func beforeConvert(_ schema: DatabaseSchema) -> DatabaseSchema {
        schema
    }
}

public struct SQLSchemaConverter {
    let delegate: any SQLConverterDelegate
    
    public init(delegate: any SQLConverterDelegate) {
        self.delegate = delegate
    }
    
    public func convert(_ schema: DatabaseSchema) -> any SQLExpression {
        let schema = self.delegate.beforeConvert(schema)
        
        return switch schema.action {
        case .create:
            self.create(schema)
        case .delete:
            self.delete(schema)
        case .update:
            self.update(schema)
        }
    }
    
    // MARK: Private

    private func update(_ schema: DatabaseSchema) -> any SQLExpression {
        var update = SQLAlterTable(name: self.name(schema.schema, space: schema.space))
    
        update.addColumns = schema.createFields.map(self.fieldDefinition)
        update.dropColumns = schema.deleteFields.map(self.fieldName)
        update.modifyColumns = schema.updateFields.map(self.fieldUpdate)
        update.addTableConstraints = schema.createConstraints.map {
            self.constraint($0, table: schema.schema)
        }
        update.dropTableConstraints = schema.deleteConstraints.map {
            self.deleteConstraint($0, table: schema.schema)
        }
        return update
    }
    
    private func delete(_ schema: DatabaseSchema) -> any SQLExpression {
        SQLDropTable(table: self.name(schema.schema, space: schema.space))
    }
    
    private func create(_ schema: DatabaseSchema) -> any SQLExpression {
        var create = SQLCreateTable(name: self.name(schema.schema, space: schema.space))
    
        create.columns = schema.createFields.map(self.fieldDefinition)
        create.tableConstraints = schema.createConstraints.map {
            self.constraint($0, table: schema.schema)
        }
        if !schema.exclusiveCreate {
            create.ifNotExists = true
        }
        return create
    }
    
    private func name(_ string: String, space: String? = nil) -> any SQLExpression {
        SQLKit.SQLQualifiedTable(string, space: space)
    }
    
    private func constraint(_ constraint: DatabaseSchema.Constraint, table: String) -> any SQLExpression {
        switch constraint {
        case .constraint(let algorithm, let customName):
            let name = customName ?? self.constraintIdentifier(algorithm, table: table)
            switch algorithm {
            case .unique(let fields):
                return SQLConstraint(
                    algorithm: SQLTableConstraintAlgorithm.unique(columns: fields.map(self.fieldName)),
                    name: SQLIdentifier(name)
                )
            case .foreignKey(let local, let schema, let space, let foreign, let onDelete, let onUpdate):
                let reference = SQLForeignKey(
                    table: self.name(schema, space: space),
                    columns: foreign.map(self.fieldName),
                    onDelete: self.foreignKeyAction(onDelete),
                    onUpdate: self.foreignKeyAction(onUpdate)
                )
                return SQLConstraint(
                    algorithm: SQLTableConstraintAlgorithm.foreignKey(
                        columns: local.map(self.fieldName),
                        references: reference
                    ),
                    name: SQLIdentifier(name)
                )
            case .compositeIdentifier(let fields):
                return SQLConstraint(algorithm: SQLTableConstraintAlgorithm.primaryKey(columns: fields.map(self.fieldName)), name: nil)
            case .custom(let any):
                return SQLConstraint(algorithm: any as! any SQLExpression, name: customName.map(SQLIdentifier.init(_:)))
            }
        case .custom(let any):
            return custom(any)
        }
    }

    private func deleteConstraint(_ constraint: DatabaseSchema.ConstraintDelete, table: String) -> any SQLExpression {
        switch constraint {
        case .constraint(let algorithm):
            let name = self.constraintIdentifier(algorithm, table: table)
            return SQLDropTypedConstraint(name: SQLIdentifier(name), algorithm: algorithm)
        case .name(let name):
            return SQLDropTypedConstraint(name: SQLIdentifier(name), algorithm: .custom(""))
        case .custom(let any):
            if let fkeyExt = any as? DatabaseSchema.ConstraintDelete._ForeignKeyByNameExtension {
                return SQLDropTypedConstraint(name: SQLIdentifier(fkeyExt.name), algorithm: .foreignKey([], "", [], onDelete: .noAction, onUpdate: .noAction))
            }
            return custom(any)
        }
    }

    private func constraintIdentifier(_ algorithm: DatabaseSchema.ConstraintAlgorithm, table: String) -> String {
        let fieldNames: [DatabaseSchema.FieldName]
        let prefix: String

        switch algorithm {
        case .foreignKey(let localFields, _, _, let foreignFields, _, _):
            prefix = "fk"
            fieldNames = localFields + foreignFields
        case .unique(let fields):
            prefix = "uq"
            fieldNames = fields
        default:
            fatalError("Constraint identifier not supported with custom constraints.")
        }

        let fieldsString = fieldNames.map { field -> String in
            switch field {
            case .custom:
                return ""
            case .key(let key):
                return "\(table).\(self.key(key))"
            }
        }.joined(separator: "+")

        return "\(prefix):\(fieldsString)"
    }


    private func foreignKeyAction(_ action: DatabaseSchema.ForeignKeyAction) -> SQLForeignKeyAction {
        switch action {
        case .noAction:
            .noAction
        case .restrict:
            .restrict
        case .cascade:
            .cascade
        case .setNull:
            .setNull
        case .setDefault:
            .setDefault
        }
    }
    
    private func fieldDefinition(_ fieldDefinition: DatabaseSchema.FieldDefinition) -> any SQLExpression {
        switch fieldDefinition {
        case .custom(let any):
            custom(any)
        case .definition(let name, let dataType, let constraints):
            SQLColumnDefinition(
                column: self.fieldName(name),
                dataType: self.dataType(dataType),
                constraints: constraints.map(self.fieldConstraint)
            )
        }
    }

    private func fieldUpdate(_ fieldDefinition: DatabaseSchema.FieldUpdate) -> any SQLExpression {
        switch fieldDefinition {
        case .custom(let any):
            custom(any)
        case .dataType(let name, let dataType):
            SQLAlterColumnDefinitionType(
                column: self.fieldName(name),
                dataType: self.dataType(dataType)
            )
        }
    }
    
    private func fieldName(_ fieldName: DatabaseSchema.FieldName) -> any SQLExpression {
        switch fieldName {
        case .key(let key):
            SQLIdentifier(self.key(key))
        case .custom(let any):
            custom(any)
        }
    }
    
    private func dataType(_ dataType: DatabaseSchema.DataType) -> any SQLExpression {
        if let custom = self.delegate.customDataType(dataType) {
            return custom
        }
        
        return switch dataType {
        case .bool:
            SQLDataType.int
        case .data:
            SQLDataType.blob
        case .date:
            SQLRaw("DATE")
        case .datetime:
            SQLRaw("TIMESTAMP")
        case .int64:
            SQLRaw("BIGINT")
        case .string:
            SQLDataType.text
        case .dictionary, .array:
            SQLRaw("JSON")
        case .uuid:
            SQLRaw("UUID")
        case .int8:
            SQLDataType.int
        case .int16:
            SQLDataType.int
        case .int32:
            SQLDataType.int
        case .uint8:
            SQLDataType.int
        case .uint16:
            SQLDataType.int
        case .uint32:
            SQLDataType.int
        case .uint64:
            SQLDataType.int
        case .enum(let value):
            SQLEnumDataType(cases: value.cases)
        case .time:
            SQLRaw("TIME")
        case .float:
            SQLRaw("FLOAT")
        case .double:
            SQLRaw("DOUBLE")
        case .custom(let any):
            custom(any)
        }
    }
    
    private func fieldConstraint(_ fieldConstraint: DatabaseSchema.FieldConstraint) -> any SQLExpression {
        switch fieldConstraint {
        case .required:
            SQLColumnConstraintAlgorithm.notNull
        case .identifier(let auto):
            SQLColumnConstraintAlgorithm.primaryKey(autoIncrement: auto)
        case .foreignKey(let schema, let space, let field, let onDelete, let onUpdate):
            SQLColumnConstraintAlgorithm.references(
                self.name(schema, space: space),
                self.fieldName(field),
                onDelete: self.foreignKeyAction(onDelete),
                onUpdate: self.foreignKeyAction(onUpdate)
            )
        case .custom(let any):
            custom(any)
        }
    }

    private func key(_ key: FieldKey) -> String { key.description }
}

/// SQL drop constraint expression with awareness of foreign keys (for MySQL's broken sake).
///
/// > Warning: This is only public for the benefit of `FluentBenchmarks`. DO NOT USE THIS TYPE!
public struct SQLDropTypedConstraint: SQLExpression {
    public let name: any SQLExpression
    public let algorithm: DatabaseSchema.ConstraintAlgorithm
    
    public init(name: any SQLExpression, algorithm: DatabaseSchema.ConstraintAlgorithm) {
        self.name = name
        self.algorithm = algorithm
    }
    
    public func serialize(to serializer: inout SQLSerializer) {
        serializer.statement {
            if $0.dialect.name == "mysql" { // TODO: Add an SQLDialect setting for this branch
                // MySQL 5.7 does not support the type-generic "DROP CONSTRAINT" syntax.
                switch algorithm {
                case .foreignKey(_, _, _, _, _, _):
                    $0.append("FOREIGN KEY")
                    $0.append($0.dialect.normalizeSQLConstraint(identifier: self.name))
                case .unique(_):
                    $0.append("KEY")
                    $0.append($0.dialect.normalizeSQLConstraint(identifier: self.name))
                // Ignore `.compositeIdentifier()`, that gets too complicated between databases
                default:
                    // Ideally we'd detect MySQL 8.0 and use `CONSTRAINT` here...
                    $0.append("KEY")
                    $0.append($0.dialect.normalizeSQLConstraint(identifier: self.name))
                }
            } else {
                $0.append("CONSTRAINT")
                $0.append($0.dialect.normalizeSQLConstraint(identifier: self.name))
            }
        }
    }
}

/// Obsolete form of SQL drop constraint expression.
///
///     `CONSTRAINT/KEY <name>`
@available(*, deprecated, message: "Use SQLDropTypedConstraint instead")
public struct SQLDropConstraint: SQLExpression {
    public var name: any SQLExpression

    public init(name: any SQLExpression) {
        self.name = name
    }

    public func serialize(to serializer: inout SQLSerializer) {
        if serializer.dialect.name == "mysql" {
            serializer.write("KEY ")
        } else {
            serializer.write("CONSTRAINT ")
        }

        let normalizedName = serializer.dialect.normalizeSQLConstraint(identifier: name)

        normalizedName.serialize(to: &serializer)
    }
}
