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
        default:
            #warning("TODO:")
            fatalError("\(self) not yet supported")
        }
    }
    
    // MARK: Private
    
    private func delete(_ schema: DatabaseSchema) -> SQLExpression {
        let delete = SQLDropTable(table: self.name(schema.entity))
        return delete
    }
    
    private func create(_ schema: DatabaseSchema) -> SQLExpression {
        var create = SQLCreateTable(name: self.name(schema.entity))
        create.columns = schema.createFields.map(self.fieldDefinition)
        create.tableConstraints = schema.constraints.map(self.constraint)
        return create
    }
    
    private func name(_ string: String) -> SQLExpression {
        return SQLIdentifier(string)
    }
    
    private func constraint(_ constraint: DatabaseSchema.Constraint) -> SQLExpression {
        switch constraint {
        case .custom(let any):
            return any as! SQLExpression
        case .unique(let fields):
            #warning("TODO: generate unique name")
            return SQLTableConstraint(
                columns: fields.map(self.fieldName),
                algorithm: SQLConstraintAlgorithm.unique,
                name: nil
            )
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
        case .custom(let any):
            return any as! SQLExpression
        case .string(let string):
            return SQLIdentifier(string)
        }
    }
    
    private func dataType(_ dataType: DatabaseSchema.DataType) -> SQLExpression {
        if let custom = self.delegate.customDataType(dataType) {
            return custom
        }
        
        switch dataType {
        case .bool: return SQLDataType.int
        case .data: return SQLDataType.blob
        case .date: return SQLRaw("DATE")
        case .datetime: return SQLRaw("TIMESTAMP")
        case .custom(let any): return any as! SQLExpression
        case .int64: return SQLDataType.bigint
        case .string: return SQLDataType.text
        case .json:
            #warning("TODO: get better support for this")
            return SQLRaw("JSON")
        case .uuid:
            #warning("TODO: get better support for this")
            return SQLRaw("UUID")
        default:
            #warning("TODO:")
            fatalError("\(dataType) not yet supported")
        }
    }
    
    private func fieldConstraint(_ fieldConstraint: DatabaseSchema.FieldConstraint) -> SQLExpression {
        switch fieldConstraint {
        case .required:
            return SQLColumnConstraint.notNull
        case .custom(let any):
            return any as! SQLExpression
        case .identifier:
            return SQLColumnConstraint.primaryKey
        }
    }
}
