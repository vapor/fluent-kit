public struct ModelParent<Child, Parent>: ModelProperty
    where Parent: Model, Child: Model
{
    public let id: Child.Field<Parent.ID>
    
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
    
    public init(id: Child.Field<Parent.ID>) {
        self.id = id
    }
    
    public func encode(to encoder: inout ModelEncoder, from storage: ModelStorage) throws {
        if let cache = storage.eagerLoads[Parent.entity] {
            let parent = try cache.get(id: storage.get(self.id.name, as: Parent.ID.self))
                .map { $0 as! Parent }
                .first!
            try encoder.encode(parent, forKey: "\(Parent.self)".lowercased())
        } else {
            try self.id.encode(to: &encoder, from: storage)
        }
    }
    
    public func decode(from decoder: ModelDecoder, to storage: inout ModelStorage) throws {
        try self.id.decode(from: decoder, to: &storage)
    }
}

extension Model {
    public typealias Parent<ParentType> = ModelParent<Self, ParentType>
        where ParentType: Model
    
    public typealias ParentKey<ParentType> = KeyPath<Self.Properties, Parent<ParentType>>
        where ParentType: Model
    
    
    public static func parent<T>(forKey key: ParentKey<T>) -> Parent<T> {
        return self.properties[keyPath: key]
    }
    
    public func set<ParentType>(_ key: Self.ParentKey<ParentType>, to parent: ParentType) throws
        where ParentType: Model
    {
        try self.set(Self.parent(forKey: key).id, to: parent.get(\.id))
    }

    public func get<ParentType>(_ key: Self.ParentKey<ParentType>) throws -> ParentType
        where ParentType: Model
    {
        guard let cache = self.storage.eagerLoads[ParentType.entity] else {
            fatalError("No cache set on storage.")
        }
        return try cache.get(id: self.get(Self.parent(forKey: key).id))
            .map { $0 as! ParentType }
            .first!
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

