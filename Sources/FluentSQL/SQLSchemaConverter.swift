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
            fatalError("Update schema not yet supported")
        }
    }
    
    // MARK: Private
    
    private func delete(_ schema: DatabaseSchema) -> SQLExpression {
        let delete = SQLDropTable(table: self.name(schema.schema))
        return delete
    }
    
    private func create(_ schema: DatabaseSchema) -> SQLExpression {
        var create = SQLCreateTable(name: self.name(schema.schema))
        create.columns = schema.createFields.map(self.fieldDefinition)
        create.tableConstraints = schema.constraints.map(self.constraint)
        return create
    }
    
    private func name(_ string: String) -> SQLExpression {
        return SQLIdentifier(string)
    }
    
    private func constraint(_ constraint: DatabaseSchema.Constraint) -> SQLExpression {
        switch constraint {
        case .unique(let fields):
            let name = fields.map { field -> String in
                switch field {
                case .custom:
                    return ""
                case .string(let name):
                    return name
                }
            }.joined(separator: "+")
            return SQLTableConstraint(
                columns: fields.map(self.fieldName),
                algorithm: SQLConstraintAlgorithm.unique,
                name: SQLIdentifier("uq:\(name)")
            )
        case .custom(let any):
            return custom(any)
        }
    }
    
    private func fieldDefinition(_ fieldDefinition: DatabaseSchema.FieldDefinition) -> SQLExpression {
        switch fieldDefinition {
        case .custom(let any):
            return any as! SQLExpression
        case .definition(let name, let dataType, let constraints):
            return SQLColumnDefinition(
                column: self.fieldName(name),
                dataType: self.dataType(dataType),
                constraints: constraints.map(self.fieldConstraint)
            )
        }
    }
    
    private func fieldName(_ fieldName: DatabaseSchema.FieldName) -> SQLExpression {
        switch fieldName {
        case .string(let string):
            return SQLIdentifier(string)
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
        case .enum:
            fatalError("SQL enums not yet supported.")
        case .time:
            return SQLRaw("TIME")
        case .float:
            return SQLRaw("FLOAT")
        case .double:
            return SQLRaw("DOUBLE")
        case .custom(let any):
            return custom(any)
        }
    }
    
    private func fieldConstraint(_ fieldConstraint: DatabaseSchema.FieldConstraint) -> SQLExpression {
        switch fieldConstraint {
        case .required:
            return SQLColumnConstraint.notNull
        case .identifier(let auto):
            return SQLColumnConstraint.primaryKey(autoIncrement: auto, name: nil)
        case .custom(let any):
            return custom(any)
        }
    }
}
