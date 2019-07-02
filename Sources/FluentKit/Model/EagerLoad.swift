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

final class SubqueryParentEagerLoad<Child, Parent>: EagerLoad
    where  Child: Model, Parent: Model
{
    var storage: [Parent]
    let parentID: String
    
    init(_ parentID: String) {
        self.storage = []
        self.parentID = parentID
    }
    
    func run(_ models: [Any], on database: Database) -> EventLoopFuture<Void> {
        let ids: [Parent.ID] = models
            .map { $0 as! Child }
            .map { try! $0.storage!.output!.decode(field: self.parentID, as: Parent.ID.self) }

        let uniqueIDs = Array(Set(ids))
        return Parent.query(on: database)
            .filter(Parent.reference.idField.name, in: uniqueIDs)
            .all()
            .map { self.storage = $0 }
    }
    
    func get(id: Any) throws -> [Any] {
        let id = id as! Parent.ID
        return self.storage.filter { parent in
            return parent.id == id
        }
    }
}

final class SubqueryChildEagerLoad<Parent, Child>: EagerLoad
    where Parent: Model, Child: Model
{
    var storage: [Child]
    let parentID: String
    
    init(_ parentID: String) {
        self.storage = []
        self.parentID = parentID
    }
    
    func run(_ models: [Any], on database: Database) -> EventLoopFuture<Void> {
        let ids: [Parent.ID] = models
            .map { $0 as! Parent }
            .map { $0.id! }
        
        let uniqueIDs = Array(Set(ids))
        return Child.query(on: database)
            .filter(self.parentID, in: uniqueIDs)
            .all()
            .map { self.storage = $0 }
    }
    
    func get(id: Any) throws -> [Any] {
        let id = id as! Parent.ID
        return try self.storage.filter { child in
            return try child.storage!.output!.decode(field: self.parentID, as: Parent.ID.self) == id
        }
    }
}
