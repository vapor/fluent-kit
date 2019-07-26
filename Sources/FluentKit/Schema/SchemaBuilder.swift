import NIO

private protocol OptionalType {
    static var wrappedType: Any.Type { get }
}
extension Optional: OptionalType {
    static var wrappedType: Any.Type {
        return Wrapped.self
    }
}

protocol AnyGeneratableID {
    static func anyGenerateID() -> Any
}

protocol GeneratableID: AnyGeneratableID {
    static func generateID() -> Self
}

extension GeneratableID {
    static func anyGenerateID() -> Any {
        self.generateID()
    }
}

extension UUID: GeneratableID {
    static func generateID() -> UUID {
        .init()
    }
}

public final class SchemaBuilder<Model> where Model: FluentKit.Model {
    let database: Database
    public var schema: DatabaseSchema
    
    public init(database: Database) {
        self.database = database
        self.schema = .init(entity: Model.entity)
    }
    
//    public func auto() -> Self {
//        self.schema.createFields = Model().fields.map { field in
//            var constraints = [DatabaseSchema.FieldConstraint]()
//            let type: Any.Type
//
//            let isOptional: Bool
//            if let optionalType = field.type as? OptionalType.Type {
//                isOptional = true
//                type = optionalType.wrappedType
//            } else {
//                isOptional = false
//                type = field.type
//            }
//
//            if field.name == Model().idField.name {
//                constraints.append(.identifier(
//                    auto: !(type is AnyGeneratableID.Type)
//                ))
//            } else if !isOptional {
//                constraints.append(.required)
//            }
//
//            return .definition(
//                name: .string(field.name),
//                dataType: .bestFor(type: type),
//                constraints: constraints
//            )
//        }
//        return self
//    }
    
    public func field<Value>(
        _ field: KeyPath<Model, Field<Value>>,
        _ dataType: DatabaseSchema.DataType,
        _ constraints: DatabaseSchema.FieldConstraint...
    ) -> Self
        where Value: Codable
    {
        return self.field(.definition(
            name: .string(Model.key(for: field)),
            dataType: dataType,
            constraints: constraints
        ))
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
    
    public func unique<A>(on a: KeyPath<Model, Field<A>>) -> Self
        where A: Codable
    {
        self.schema.constraints.append(.unique(fields: [
            .string(Model.key(for: a))
        ]))
        return self
    }
    
    public func unique<A, B>(on a: KeyPath<Model, Field<A>>, _ b: KeyPath<Model, Field<B>>) -> Self
        where A: Codable, B: Codable
    {
        self.schema.constraints.append(.unique(fields: [
            .string(Model.key(for: a)), .string(Model.key(for: b))
        ]))
        return self
    }
    
    public func unique<A, B, C>(on a: KeyPath<Model, Field<A>>, _ b: KeyPath<Model, Field<B>>,_ c: KeyPath<Model, Field<C>>) -> Self
        where A: Codable, B: Codable, C: Codable
    {
        self.schema.constraints.append(.unique(fields: [
            .string(Model.key(for: a)), .string(Model.key(for: b)), .string(Model.key(for: c))
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
