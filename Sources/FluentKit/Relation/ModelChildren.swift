public struct ModelChildren<Parent, Child>
    where Child: Model, Parent: Model
{
    public let id: Field<Parent.ID>
    
    public init(_ id: Field<Parent.ID>) {
        self.id = id
    }
    
    func encode(to encoder: inout ModelEncoder, from storage: ModelStorage) throws {
        #warning("TODO: fixme")
    }
    
    func decode(from decoder: ModelDecoder, to storage: inout ModelStorage) throws {
        #warning("TODO: fixme")
    }
}



extension Model {
    public typealias Children<ChildType> = ModelChildren<Self, ChildType>
        where ChildType: Model
    
    
    public typealias ChildrenKey<ChildType> = KeyPath<Self, Children<ChildType>>
        where ChildType: Model
    
    
    public static func children<T>(forKey key: ChildrenKey<T>) -> Children<T> {
        return self.shared[keyPath: key]
    }
}
