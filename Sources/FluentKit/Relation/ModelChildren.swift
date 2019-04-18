public final class ModelChildren<Parent, Child>: ModelProperty
    where Child: Model, Parent: Model
{
    public var name: String {
        return "\(Child.self)".lowercased() + "s"
    }

    public var type: Any.Type {
        return [Child].self
    }

    public var isStored: Bool {
        return false
    }

    internal var cache: (EagerLoad, Parent.ID)?

    public func load(from storage: ModelStorage) throws {
        if let cache = storage.eagerLoads[Child.entity] {
            let id = try storage.output!.decode(field: Parent.default.id.name, as: Parent.ID.self)
            self.cache = (cache, id)
        }
    }

    public var id: ModelField<Child, Parent.ID>
    
    public init(_ id: KeyPath<Child, ModelParent<Child, Parent>>) {
        self.id = .init(Child.default[keyPath: id].name)
    }

    public func get() -> [Child] {
        guard let (cache, id) = self.cache else {
            fatalError("Children \(Child.self) were not eager loaded")
        }
        #warning("TODO: each model needs its own view into the cache")
        return try! cache.get(id: id)
            .map { $0 as! Child }
    }
    
    public func encode(to encoder: inout ModelEncoder) throws {
        if self.cache != nil {
            try encoder.encode(self.get(), forKey: self.name)
        }
    }

    public func decode(from decoder: ModelDecoder) throws {
        // do nothing
    }
}



extension Model {
    public typealias Children<ChildType> = ModelChildren<Self, ChildType>
        where ChildType: Model


    public typealias ChildrenKey<ChildType> = KeyPath<Self, Children<ChildType>>
        where ChildType: Model


    public func children<T>(forKey key: ChildrenKey<T>) -> Children<T> {
        return self[keyPath: key]
    }
}

//extension ModelRow {
//    public func query<Child>(_ key: Model.ChildrenKey<Child>, on database: Database) throws -> QueryBuilder<Child>
//        where Child: FluentKit.Model
//    {
//        let children = Model.children(forKey: key)
//        return try database.query(Child.self)
//            .filter(children.id, .equals, self.get(\.id))
//    }
//    
//    public func get<Child>(_ key: Model.ChildrenKey<Child>) throws -> [Child.Row]
//        where Child: FluentKit.Model
//    {

//    }
//}
