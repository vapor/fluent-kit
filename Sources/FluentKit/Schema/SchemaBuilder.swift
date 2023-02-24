extension Database {
    public func schema(_ schema: String, space: String? = nil) -> SchemaBuilder {
        return .init(database: self, schema: schema, space: space)
    }
}

import NIOCore

public final class SchemaBuilder {
    let database: Database
    public var schema: DatabaseSchema

    init(database: Database, schema: String, space: String? = nil) {
        self.database = database
        self.schema = .init(schema: schema, space: space)
    }

    @discardableResult
    public func id() -> Self {
        self.field(.id, .uuid, .identifier(auto: false))
    }

    @discardableResult
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

    @discardableResult
    public func field(_ field: DatabaseSchema.FieldDefinition) -> Self {
        self.schema.createFields.append(field)
        return self
    }

    @discardableResult
    public func unique(on fields: FieldKey..., name: String? = nil) -> Self {
        self.constraint(.constraint(
            .unique(fields: fields.map { .key($0) }),
            name: name
        ))
    }
    
    @discardableResult
    public func compositeIdentifier(over fields: FieldKey...) -> Self {
        self.constraint(.constraint(.compositeIdentifier(fields.map { .key($0) }), name: ""))
    }

    @discardableResult
    public func constraint(_ constraint: DatabaseSchema.Constraint) -> Self {
        self.schema.createConstraints.append(constraint)
        return self
    }

    @discardableResult
    public func deleteUnique(on fields: FieldKey...) -> Self {
        self.schema.deleteConstraints.append(.constraint(
            .unique(fields: fields.map { .key($0) })
        ))
        return self
    }

    @discardableResult
    public func deleteConstraint(name: String) -> Self {
        self.schema.deleteConstraints.append(.name(name))
        return self
    }

    @discardableResult
    public func deleteConstraint(_ constraint: DatabaseSchema.ConstraintDelete) -> Self {
        self.schema.deleteConstraints.append(constraint)
        return self
    }

    @discardableResult
    public func foreignKey(
        _ field: FieldKey,
        references foreignSchema: String,
        inSpace foreignSpace: String? = nil,
        _ foreignField: FieldKey,
        onDelete: DatabaseSchema.ForeignKeyAction = .noAction,
        onUpdate: DatabaseSchema.ForeignKeyAction = .noAction,
        name: String? = nil
    ) -> Self {
        self.schema.createConstraints.append(.constraint(
            .foreignKey(
                [.key(field)],
                foreignSchema,
                space: foreignSpace,
                [.key(foreignField)],
                onDelete: onDelete,
                onUpdate: onUpdate
            ),
            name: name
        ))
        return self
    }

    @discardableResult
    public func foreignKey(
        _ fields: [FieldKey],
        references foreignSchema: String,
        inSpace foreignSpace: String? = nil,
        _ foreignFields: [FieldKey],
        onDelete: DatabaseSchema.ForeignKeyAction = .noAction,
        onUpdate: DatabaseSchema.ForeignKeyAction = .noAction,
        name: String? = nil
    ) -> Self {
        self.schema.createConstraints.append(.constraint(
            .foreignKey(
                fields.map { .key($0) },
                foreignSchema,
                space: foreignSpace,
                foreignFields.map { .key($0) },
                onDelete: onDelete,
                onUpdate: onUpdate
            ),
            name: name
        ))
        return self
    }

    @discardableResult
    public func updateField(
        _ key: FieldKey,
        _ dataType: DatabaseSchema.DataType
    ) -> Self {
        self.updateField(.dataType(
            name: .key(key),
            dataType: dataType
        ))
    }

    @discardableResult
    public func updateField(_ field: DatabaseSchema.FieldUpdate) -> Self {
        self.schema.updateFields.append(field)
        return self
    }

    @discardableResult
    public func deleteField(_ name: FieldKey) -> Self {
        return self.deleteField(.key(name))
    }

    @discardableResult
    public func deleteField(_ name: DatabaseSchema.FieldName) -> Self {
        self.schema.deleteFields.append(name)
        return self
    }

    @discardableResult
    public func ignoreExisting() -> Self {
        self.schema.exclusiveCreate = false
        return self
    }

    public func create() -> EventLoopFuture<Void> {
        self.schema.action = .create
        return self.database.execute(schema: self.schema)
    }

    public func update() -> EventLoopFuture<Void> {
        self.schema.action = .update
        return self.database.execute(schema: self.schema)
    }

    public func delete() -> EventLoopFuture<Void> {
        self.schema.action = .delete
        return self.database.execute(schema: self.schema)
    }
}
