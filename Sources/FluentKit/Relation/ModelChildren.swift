public struct ModelChildren<Parent, Child>
    where Child: Model, Parent: Model
{
    public let id: ModelField<Child, Parent.ID>
    
    public init(id: ModelField<Child, Parent.ID>) {
        self.id = id
    }
    
    public func encode(to encoder: inout ModelEncoder, from storage: ModelStorage) throws {
        #warning("TODO: fixme")
    }
    
    public func decode(from decoder: ModelDecoder, to storage: inout ModelStorage) throws {
        #warning("TODO: fixme")
    }
}



extension Model {
    public typealias Children<ChildType> = ModelChildren<Self, ChildType>
        where ChildType: Model
    
    
    public typealias ChildrenKey<ChildType> = KeyPath<Self, Children<ChildType>>
        where ChildType: Model
    
    
    public static func children<T>(forKey key: ChildrenKey<T>) -> Children<T> {
        return self.default[keyPath: key]
    }
}

extension ModelRow {
    public func query<Child>(_ key: Model.ChildrenKey<Child>, on database: Database) throws -> QueryBuilder<Child>
        where Child: FluentKit.Model
    {
        let children = Model.children(forKey: key)
        return try database.query(Child.self)
            .filter(children.id, .equals, self.get(\.id))
    }
    
    public func get<Child>(_ key: Model.ChildrenKey<Child>) throws -> [Child.Row]
        where Child: FluentKit.Model
    {
        guard let cache = self.storage.eagerLoads[Child.entity] else {
            fatalError("No cache set on storage.")
        }
        return try cache.get(id: self.get(\.id))
            .map { $0 as! Child.Row }
    }
}
