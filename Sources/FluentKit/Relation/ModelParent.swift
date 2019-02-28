public struct ModelParent<Child, Parent>
    where Child: Model, Parent: Model
{
    public var id: ModelField<Child, Parent.ID>
    
    init(id: ModelField<Child, Parent.ID>) {
        self.id = id
    }
    
    public func set(to parent: Parent) throws {
        try self.id.set(to: parent.id.get())
    }
    
    public func get() throws -> Parent {
        guard let cache = self.id.model.storage.eagerLoads[Parent().entity] else {
            fatalError("No cache set on storage.")
        }
        return try cache.get(id: self.id.get())
            .map { $0 as! Parent }
            .first!
    }
}

extension ModelParent: ModelProperty {
    public var name: String {
        return self.id.name
    }
    
    public var type: Any.Type {
        return self.id.type
    }
    
    public var dataType: DatabaseSchema.DataType? {
        return self.id.dataType
    }
    
    public var constraints: [DatabaseSchema.FieldConstraint] {
        return self.id.constraints
    }
    
    public func encode(to encoder: inout ModelEncoder) throws {
        if self.id.model.storage.eagerLoads[Parent().entity] != nil {
            let parent = try self.get()
            try encoder.encode(parent, forKey: "\(Parent.self)".lowercased())
        } else {
            try self.id.encode(to: &encoder)
        }
    }
    
    public func decode(from decoder: ModelDecoder) throws {
        try self.id.decode(from: decoder)
    }
}


extension Model {
    public typealias Parent<Model> = ModelParent<Self, Model>
        where Model: FluentKit.Model
    
    public func parent<Model>(_ name: String, _ dataType: DatabaseSchema.DataType? = nil) -> Parent<Model>
        where Model: FluentKit.Model
    {
        return .init(id: self.field(name, dataType))
    }
}
