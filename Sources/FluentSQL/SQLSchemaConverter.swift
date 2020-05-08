public protocol SQLConverterDelegate {
    func customDataType(_ dataType: DatabaseSchema.DataType) -> SQLExpression?
    func nestedFieldExpression(_ column: String, _ path: [String]) -> SQLExpression
}

public struct SQLSchemaConverter {
    let delegate: SQLConverterDelegate
    public init(delegate: SQLConverterDelegate) {
        self.delegate = delegate
    }
    
    public func convert(_ schema: DatabaseSchema) -> SQLExpression {
        switch schema.action {
        case .create:
            return self.create(schema)
        case .delete:
            return self.delete(schema)
        case .update:
            return self.update(schema)
        }
    }
    
    // MARK: Private

    private func update(_ schema: DatabaseSchema) -> SQLExpression {
        var update = SQLAlterTable(name: self.name(schema.schema))
        update.addColumns = schema.createFields.map(self.fieldDefinition)
        update.dropColumns = schema.deleteFields.map(self.fieldName)
        update.modifyColumns = schema.updateFields.map(self.fieldUpdate)
        return update
    }
    
    private func delete(_ schema: DatabaseSchema) -> SQLExpression {
        let delete = SQLDropTable(table: self.name(schema.schema))
        return delete
    }
    
    private func create(_ schema: DatabaseSchema) -> SQLExpression {
        var create = SQLCreateTable(name: self.name(schema.schema))
        create.columns = schema.createFields.map(self.fieldDefinition)
        create.tableConstraints = schema.constraints.map {
            self.constraint($0, table: schema.schema)
        }
        if !schema.exclusiveCreate {
            create.ifNotExists = true
        }
        return create
    }
    
    private func name(_ string: String) -> SQLExpression {
        return SQLIdentifier(string)
    }
    
    private func constraint(_ constraint: DatabaseSchema.Constraint, table: String) -> SQLExpression {
        func identifier(_ fields: [DatabaseSchema.FieldName]) -> String {
            return fields.map { field -> String in
                switch field {
                case .custom:
                    return ""
                case .key(let key):
                    return "\(table).\(self.key(key))"
                }
            }.joined(separator: "+")
        }

        switch constraint {
        case .constraint(let constraint, let customName):
            switch constraint {
            case .unique(let fields):
                let name = customName ?? identifier(fields)
                return SQLConstraint(
                    algorithm: SQLTableConstraintAlgorithm.unique(columns: fields.map(self.fieldName)),
                    name: SQLIdentifier("uq:\(name)")
                )
            case .foreignKey(let local, let schema, let foreign, let onDelete, let onUpdate):
                let name = customName ?? identifier(local + foreign)
                let reference = SQLForeignKey(
                    table: self.name(schema),
                    columns: foreign.map(self.fieldName),
                    onDelete: self.foreignKeyAction(onDelete),
                    onUpdate: self.foreignKeyAction(onUpdate)
                )

                return SQLConstraint(
                    algorithm: SQLTableConstraintAlgorithm.foreignKey(
                        columns: local.map(self.fieldName),
                        references: reference
                    ),
                    name: SQLIdentifier("fk:\(name)")
                )
            case .custom(let any):
                return custom(any)
            }
        case .custom(let any):
            return custom(any)
        }
    }

    private func foreignKeyAction(_ action: DatabaseSchema.ForeignKeyAction) -> SQLForeignKeyAction {
        switch action {
        case .noAction:
            return .noAction
        case .restrict:
            return .restrict
        case .cascade:
            return .cascade
        case .setNull:
            return .setNull
        case .setDefault:
            return .setDefault
        }
    }
    
    private func fieldDefinition(_ fieldDefinition: DatabaseSchema.FieldDefinition) -> SQLExpression {
        switch fieldDefinition {
        case .custom(let any):
            return custom(any)
        case .definition(let name, let dataType, let constraints):
            return SQLColumnDefinition(
                column: self.fieldName(name),
                dataType: self.dataType(dataType),
                constraints: constraints.map(self.fieldConstraint)
            )
        }
    }

    private func fieldUpdate(_ fieldDefinition: DatabaseSchema.FieldUpdate) -> SQLExpression {
        switch fieldDefinition {
        case .custom(let any):
            return custom(any)
        case .dataType(let name, let dataType):
            return SQLAlterColumnDefinitionType(
                column: self.fieldName(name),
                dataType: self.dataType(dataType)
            )
        }
    }
    
    private func fieldName(_ fieldName: DatabaseSchema.FieldName) -> SQLExpression {
        switch fieldName {
        case .key(let key):
            return SQLIdentifier(self.key(key))
        case .custom(let any):
            return custom(any)
        }
    }
    
    private func dataType(_ dataType: DatabaseSchema.DataType) -> SQLExpression {
        if let custom = self.delegate.customDataType(dataType) {
            return custom
        }
        
        switch dataType {
        case .bool:
            return SQLDataType.int
        case .data:
            return SQLDataType.blob
        case .date:
            return SQLRaw("DATE")
        case .datetime:
            return SQLRaw("TIMESTAMP")
        case .int64:
            return SQLRaw("BIGINT")
        case .string:
            return SQLDataType.text
        case .json:
            return SQLRaw("JSON")
        case .uuid:
            return SQLRaw("UUID")
        case .int8:
            return SQLDataType.int
        case .int16:
            return SQLDataType.int
        case .int32:
            return SQLDataType.int
        case .uint8:
            return SQLDataType.int
        case .uint16:
            return SQLDataType.int
        case .uint32:
            return SQLDataType.int
        case .uint64:
            return SQLDataType.int
        case .enum(let value):
            return SQLEnumDataType(cases: value.cases)
        case .time:
            return SQLRaw("TIME")
        case .float:
            return SQLRaw("FLOAT")
        case .double:
            return SQLRaw("DOUBLE")
        case .array(of: let type):
            return SQLArrayDataType(type: self.dataType(type))
        case .custom(let any):
            return custom(any)
        }
    }
    
    private func fieldConstraint(_ fieldConstraint: DatabaseSchema.FieldConstraint) -> SQLExpression {
        switch fieldConstraint {
        case .required:
            return SQLColumnConstraintAlgorithm.notNull
        case .identifier(let auto):
            return SQLColumnConstraintAlgorithm.primaryKey(autoIncrement: auto)
        case .foreignKey(let schema, let field, let onDelete, let onUpdate):
            return SQLColumnConstraintAlgorithm.references(
                SQLIdentifier(schema),
                self.fieldName(field),
                onDelete: self.foreignKeyAction(onDelete),
                onUpdate: self.foreignKeyAction(onUpdate)
            )
        case .custom(let any):
            return custom(any)
        }
    }

    private func key(_ key: FieldKey) -> String {
        switch key {
        case .id:
            return "id"
        case .string(let name):
            return name
        case .aggregate:
            return key.description
        case .prefix(let prefix, let key):
            return self.key(prefix) + self.key(key)
        }
    }
}

struct SQLArrayDataType: SQLExpression {
    let type: SQLExpression
    func serialize(to serializer: inout SQLSerializer) {
        self.type.serialize(to: &serializer)
        serializer.write("[]")
    }
}
