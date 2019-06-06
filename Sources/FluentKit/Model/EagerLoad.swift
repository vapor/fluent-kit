protocol EagerLoad: class {
    func run(_ models: [Any], on database: Database) -> EventLoopFuture<Void>
    func get(id: Any) throws -> [Any]
}

final class JoinParentEagerLoad<Child, Parent>: EagerLoad
    where Child: Model, Parent: Model
{
    var parents: [Parent.ID: Parent]
    
    init() {
        self.parents = [:]
    }
    
    func run(_ models: [Any], on database: Database) -> EventLoopFuture<Void> {
        var res: [Parent.ID: Parent] = [:]
        try! models.map { $0 as! Child }.forEach { child in
            let parent = try child.joined(Parent.self)
            res[parent.id!] = parent
        }
        
        self.parents = res
        return database.eventLoop.makeSucceededFuture(())
    }
    
    func get(id: Any) throws -> [Any] {
        let id = id as! Parent.ID
        return [self.parents[id]!]
    }
}

final class SubqueryParentEagerLoad<ChildType, ParentType>: EagerLoad
    where  ChildType: Model, ParentType: Model
{
    var storage: [ParentType]
    let keyPath: KeyPath<ChildType, Parent<ParentType>>
    
    init(_ keyPath: KeyPath<ChildType, Parent<ParentType>>) {
        self.storage = []
        self.keyPath = keyPath
    }
    
    func run(_ models: [Any], on database: Database) -> EventLoopFuture<Void> {
        let ids: [ParentType.ID] = models
            .map { $0 as! ChildType }
            .map { $0[keyPath: self.keyPath].id! }

        let uniqueIDs = Array(Set(ids))
        return ParentType.query(on: database)
            .filter(\.id, in: uniqueIDs)
            .all()
            .map { self.storage = $0 }
    }
    
    func get(id: Any) throws -> [Any] {
        let id = id as! ParentType.ID
        return self.storage.filter { parent in
            return parent.id == id
        }
    }
}

final class SubqueryChildEagerLoad<ParentType, ChildType>: EagerLoad
    where ParentType: Model, ChildType: Model
{
    var storage: [ChildType]
    let keyPath: KeyPath<ChildType, ParentType.ID>

    init(_ keyPath: KeyPath<ChildType, ParentType.ID>) {
        self.storage = []
        self.keyPath = keyPath
    }
    
    func run(_ models: [Any], on database: Database) -> EventLoopFuture<Void> {
        let ids: [ParentType.ID] = models
            .map { $0 as! ParentType }
            .map { $0.id! }
        
        let uniqueIDs = Array(Set(ids))
        return ChildType.query(on: database)
            .filter(self.keyPath, in: uniqueIDs)
            .all()
            .map { self.storage = $0 }
    }
    
    func get(id: Any) throws -> [Any] {
        let id = id as! ParentType.ID
        return self.storage.filter { child in
            return child[keyPath: self.keyPath] == id
        }
    }
}
