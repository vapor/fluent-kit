import NIO

extension Database {
    public func schema<Model>(_ model: Model.Type) -> SchemaBuilder<Model>
        where Model: FluentKit.Model
    {
        return .init(database: self)
    }
}

private protocol OptionalType {
    static var wrappedType: Any.Type { get }
}
extension Optional: OptionalType {
    static var wrappedType: Any.Type {
        return Wrapped.self
    }
}

public final class SchemaBuilder<Model> where Model: FluentKit.Model {
    let database: Database
    public var schema: DatabaseSchema
    
    public init(database: Database) {
        self.database = database
        self.schema = .init(entity: Model().entity)
    }
    
    public func auto() -> Self {
        self.schema.createFields = Model().properties.map { field in
            var constraints = field.constraints
            let type: Any.Type
            if let optionalType = field.type as? OptionalType.Type {
                type = optionalType.wrappedType
            } else {
                type = field.type
                if field.constraints.isEmpty {
                    constraints.append(.required)
                }
            }
            return .definition(
                name: .string(field.name),
                dataType: field.dataType ?? .bestFor(type: type),
                constraints: constraints
            )
        }
        return self
    }
    
    public func field<Value>(_ keyPath: KeyPath<Model, ModelField<Model, Value>>) -> Self {
        let field = Model()[keyPath: keyPath]
        return self.field(.definition(
            name: .string(field.name),
            dataType: field.dataType ?? .bestFor(type: Value.self),
            constraints: field.constraints
        ))
    }
    
    public func field(_ field: DatabaseSchema.FieldDefinition) -> Self {
        self.schema.createFields.append(field)
        return self
    }
    
    public func unique<A>(
        on a: KeyPath<Model, ModelField<Model, A>>
    ) -> Self {
        let a = Model()[keyPath: a]
        self.schema.constraints.append(.unique(fields: [
            .string(a.name)
        ]))
        return self
    }
    
    public func unique<A, B>(
        on a: KeyPath<Model, ModelField<Model, A>>,
        _ b: KeyPath<Model, ModelField<Model, B>>
    ) -> Self {
        let a = Model()[keyPath: a]
        let b = Model()[keyPath: b]
        self.schema.constraints.append(.unique(fields: [
            .string(a.name), .string(b.name)
        ]))
        return self
    }
    
    public func unique<A, B, C>(
        on a: KeyPath<Model, ModelField<Model, A>>,
        _ b: KeyPath<Model, ModelField<Model, B>>,
        _ c: KeyPath<Model, ModelField<Model, C>>
    ) -> Self {
        let a = Model()[keyPath: a]
        let b = Model()[keyPath: b]
        let c = Model()[keyPath: c]
        self.schema.constraints.append(.unique(fields: [
            .string(a.name), .string(b.name), .string(c.name)
        ]))
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
