public struct ModelChildren<Parent, Child>
    where Parent: FluentKit.Model, Child: FluentKit.Model
{
    let parent: Parent
    let relation: KeyPath<Child, ModelParent<Child, Parent>>
    
    init(parent: Parent, relation: KeyPath<Child, ModelParent<Child, Parent>>) {
        self.parent = parent
        self.relation = relation
    }
    
    public func query(on database: Database) throws -> QueryBuilder<Child> {
        let field = Child()[keyPath: self.relation].id
        return try database.query(Child.self).filter(
            .field(path: [field.name], entity: Child().entity, alias: nil),
            .equality(inverse: false),
            .bind(self.parent.id.get())
        )
    }
    
    public func get() throws -> [Child] {
        guard let cache = self.parent.storage.eagerLoads[Child().entity] else {
            fatalError("No cache set on storage.")
        }
        return try cache.get(id: self.parent.id.get())
            .map { $0 as! Child }
    }
}

extension Model {
    public typealias Children<Model> = ModelChildren<Self, Model>
        where Model: FluentKit.Model
    
    public func children<Model>(_ relation: KeyPath<Model, ModelParent<Model, Self>>) -> Children<Model>
        where Model: FluentKit.Model
    {
        return .init(parent: self, relation: relation)
    }
}
