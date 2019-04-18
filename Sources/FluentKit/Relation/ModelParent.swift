public final class ModelParent<Child, Parent>: ModelProperty
    where Parent: Model, Child: Model
{
    public var name: String {
        return self.id.name
    }

    public var dataType: DatabaseSchema.DataType? {
        return self.id.dataType
    }

    public var constraints: [DatabaseSchema.FieldConstraint]? {
        return self.id.constraints
    }

    public var type: Any.Type {
        return Parent.ID.self
    }

    public var id: ModelField<Child, Parent.ID>

    internal var cache: (EagerLoad, Parent.ID)?

    public init(
        _ name: String,
        dataType: DatabaseSchema.DataType? = nil,
        constraints: [DatabaseSchema.FieldConstraint]? = nil
    ) {
        self.id = .init(name, dataType: dataType, constraints: constraints)
    }

    public var input: Encodable? {
        return self.id.input
    }

    public func load(from storage: ModelStorage) throws {
        if let cache = storage.eagerLoads[Parent.entity] {
            let id = try storage.output!.decode(field: self.id.name, as: Parent.ID.self)
            self.cache = (cache, id)
        }
        try self.id.load(from: storage)
    }
    
    public func encode(to encoder: inout ModelEncoder) throws {
        if cache != nil {
            try encoder.encode(self.get(), forKey: "\(Parent.self)".lowercased())
        } else {
            try self.id.encode(to: &encoder)
        }
    }
    
    public func decode(from decoder: ModelDecoder) throws {
        try self.id.decode(from: decoder)
    }

    public func get() -> Parent {
        guard let (cache, id) = self.cache else {
            fatalError("\(Parent.self) was not eager loaded.")
        }
        return try! cache.get(id: id)
            .map { $0 as! Parent }
            .first!
    }
}

extension Model {
    public typealias Parent<ParentType> = ModelParent<Self, ParentType>
        where ParentType: Model
    
    public typealias ParentKey<ParentType> = KeyPath<Self, Parent<ParentType>>
        where ParentType: Model
    
    public func parent<T>(forKey key: ParentKey<T>) -> Parent<T> {
        return self[keyPath: key]
    }
}

//
//extension ModelParent: ModelProperty {
//    public var name: String {
//        return self.id.name
//    }
//
//    public var type: Any.Type {
//        return self.id.type
//    }
//
//    public var dataType: DatabaseSchema.DataType? {
//        return self.id.dataType
//    }
//
//    public var constraints: [DatabaseSchema.FieldConstraint] {
//        return self.id.constraints
//    }
//
//    public func encode(to encoder: inout ModelEncoder) throws {

//    }
//
//    public func decode(from decoder: ModelDecoder) throws {
//        try self.id.decode(from: decoder)
//    }
//}

