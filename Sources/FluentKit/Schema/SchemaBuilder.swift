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
        self.schema = .init(entity: Model.entity)
    }
    
    public func auto() -> Self {
        self.schema.createFields = Model.shared.fields.map { (name, field) in
            var constraints = field.constraints
            let type: Any.Type
            if name == Model.name(for: \.id) {
                constraints.append(.identifier)
                type = field.type
            } else {
                if let optionalType = field.type as? OptionalType.Type {
                    type = optionalType.wrappedType
                } else {
                    type = field.type
                    if field.constraints.isEmpty {
                        constraints.append(.required)
                    }
                }
            }
            return .definition(
                name: .string(name),
                dataType: field.dataType ?? .bestFor(type: type),
                constraints: constraints
            )
        }
        return self
    }
    
    public func field<Value>(_ keyPath: KeyPath<Model, Value>) -> Self
        where Value: Codable
    {
        let field = Model.field(for: keyPath)
        return self.field(.definition(
            name: .string(field.name!),
            dataType: field.dataType ?? .bestFor(type: Value.self),
            constraints: field.constraints
        ))
    }
    
    public func field(_ field: DatabaseSchema.FieldDefinition) -> Self {
        self.schema.createFields.append(field)
        return self
    }
    
    public func unique<A>(on a: KeyPath<Model, A>) -> Self
        where A: Codable
    {
        self.schema.constraints.append(.unique(fields: [
            .string(Model.name(for: a))
        ]))
        return self
    }
    
    public func unique<A, B>(on a: KeyPath<Model, A>, _ b: KeyPath<Model, B>) -> Self
        where A: Codable, B: Codable
    {
        self.schema.constraints.append(.unique(fields: [
            .string(Model.name(for: a)), .string(Model.name(for: b))
        ]))
        return self
    }
    
    public func unique<A, B, C>(on a: KeyPath<Model, A>, _ b: KeyPath<Model, B>,_ c: KeyPath<Model, C>) -> Self
        where A: Codable, B: Codable, C: Codable
    {
        self.schema.constraints.append(.unique(fields: [
            .string(Model.name(for: a)), .string(Model.name(for: b)), .string(Model.name(for: c))
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
