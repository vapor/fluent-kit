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
        _ key: FieldKey,
        _ dataType: DatabaseSchema.DataType,
        _ constraints: DatabaseSchema.FieldConstraint...
    ) -> Self {
        self.field(.definition(
            name: .key(key),
            dataType: dataType,
            constraints: constraints
        ))
    }
    
    public func field(_ field: DatabaseSchema.FieldDefinition) -> Self {
        self.schema.createFields.append(field)
        return self
    }

    public func unique(on fields: FieldKey...) -> Self {
        self.schema.constraints.append(.unique(
            fields: fields.map { .key($0) }
        ))
        return self
    }

    public func foreignKey(
        _ field: FieldKey,
        references foreignSchema: String,
        _ foreignField: FieldKey,
        onDelete: DatabaseSchema.Constraint.ForeignKeyAction = .noAction,
        onUpdate: DatabaseSchema.Constraint.ForeignKeyAction = .noAction
    ) -> Self {
        self.schema.constraints.append(.foreignKey(
            fields: [.key(field)],
            foreignSchema: foreignSchema,
            foreignFields: [.key(foreignField)],
            onDelete: onDelete,
            onUpdate: onUpdate
        ))
        return self
    }

    public func deleteField(_ name: FieldKey) -> Self {
        return self.deleteField(.key(name))
    }
    
    public func deleteField(_ name: DatabaseSchema.FieldName) -> Self {
        self.schema.deleteFields.append(name)
        return self
    }
    
    public func delete() -> EventLoopFuture<Void> {
        self.schema.action = .delete
        return self.database.execute(schema: self.schema)
    }
    
    public func update() -> EventLoopFuture<Void> {
        self.schema.action = .update
        return self.database.execute(schema: self.schema)
    }
    
    public func create() -> EventLoopFuture<Void> {
        self.schema.action = .create
        return self.database.execute(schema: self.schema)
    }
}

// MARK: - FieldConstraints

extension DatabaseSchema.FieldConstraint {
    public static func references(
        _ schema: String,
        _ field: String
    ) -> Self {
        return .foreignKey(field: .string(schema: schema, field: field), onDelete: .noAction, onUpdate: .noAction)
    }

    public static func references(
        _ schema: String,
        _ field: String,
        onDelete: DatabaseSchema.Constraint.ForeignKeyAction,
        onUpdate: DatabaseSchema.Constraint.ForeignKeyAction
    ) -> Self {
        return .foreignKey(field: .string(schema: schema, field: field), onDelete: onDelete, onUpdate: onUpdate)
    }
}
