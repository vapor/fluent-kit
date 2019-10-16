import NIO

extension Database {
    public func schema(_ schema: String) -> SchemaBuilder {
        return .init(database: self, schema: schema)
    }
}

public final class SchemaBuilder {
    let database: Database
    public var schema: DatabaseSchema
    
    init(database: Database, schema: String) {
        self.database = database
        self.schema = .init(schema: schema)
    }

    public func field(
        _ name: String,
        _ dataType: DatabaseSchema.DataType,
        _ constraints: DatabaseSchema.FieldConstraint...
    ) -> Self {
        return self.field(.definition(
            name: .string(name),
            dataType: dataType,
            constraints: constraints
        ))
    }
    
    public func field(_ field: DatabaseSchema.FieldDefinition) -> Self {
        self.schema.createFields.append(field)
        return self
    }
    
    public func unique(on fields: String...) -> Self {
        self.schema.constraints.append(.unique(
            fields: fields.map { .string($0) }
        ))
        return self
    }

    public func foreignKey(_ field: String, references parent: (table: String, field: String), onUpdate: DatabaseSchema.Constraint.ForeignKeyAction = .noAction, onDelete: DatabaseSchema.Constraint.ForeignKeyAction = .noAction) -> Self {
        self.schema.constraints.append(.foreignKey(
            fields: [.string(field)],
            parentTable: parent.table,
            parentFields: [.string(parent.field)],
            updateAction: onUpdate,
            deleteAction: onDelete
        ))
        return self
    }

    public func foreignKey(_ fields: (String, String), references parent: (table: String, fields: (String, String)), onUpdate: DatabaseSchema.Constraint.ForeignKeyAction = .noAction, onDelete: DatabaseSchema.Constraint.ForeignKeyAction = .noAction) -> Self {
        self.schema.constraints.append(.foreignKey(
            fields: [.string(fields.0), .string(fields.1)],
            parentTable: parent.table,
            parentFields: [.string(parent.fields.0), .string(parent.fields.1)],
            updateAction: onUpdate,
            deleteAction: onDelete
            ))
        return self
    }

    public func foreignKey(_ fields: (String, String, String), references parent: (table: String, fields: (String, String, String)), onUpdate: DatabaseSchema.Constraint.ForeignKeyAction = .noAction, onDelete: DatabaseSchema.Constraint.ForeignKeyAction = .noAction) -> Self {
        self.schema.constraints.append(.foreignKey(
            fields: [.string(fields.0), .string(fields.1), .string(fields.2)],
            parentTable: parent.table,
            parentFields: [.string(parent.fields.0), .string(parent.fields.1), .string(parent.fields.2)],
            updateAction: onUpdate,
            deleteAction: onDelete
            ))
        return self
    }
    
    public func deleteField(_ name: String) -> Self {
        return self.deleteField(.string(name))
    }
    
    public func deleteField(_ name: DatabaseSchema.FieldName) -> Self {
        self.schema.deleteFields.append(name)
        return self
    }
    
    public func delete() -> EventLoopFuture<Void> {
        self.schema.action = .delete
        return self.database.execute(self.schema)
    }
    
    public func update() -> EventLoopFuture<Void> {
        self.schema.action = .update
        return self.database.execute(self.schema)
    }
    
    public func create() -> EventLoopFuture<Void> {
        self.schema.action = .create
        return self.database.execute(self.schema)
    }
}
