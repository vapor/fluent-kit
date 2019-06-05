protocol EagerLoad: class {
    func run(_ models: [Any], on database: Database) -> EventLoopFuture<Void>
    func get(id: Any) throws -> [Any]
}

final class JoinParentEagerLoad<Child, Parent>: EagerLoad
    where Child: Model, Parent: Model
{
    var parents: [Parent.ID: Row<Parent>]
    
    init() {
        self.parents = [:]
    }
    
    func run(_ models: [Any], on database: Database) -> EventLoopFuture<Void> {
        var res: [Parent.ID: Row<Parent>] = [:]
        try! models.map { $0 as! Row<Child> }.forEach { child in
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
    var storage: [Row<Parent>]
    let parentID: String
    
    init(_ parentID: String) {
        self.storage = []
        self.parentID = parentID
    }
    
    func run(_ models: [Any], on database: Database) -> EventLoopFuture<Void> {
        let ids: [Parent.ID] = models
            .map { $0 as! Row<Child> }
            .map { $0.get(self.parentID) }

        let uniqueIDs = Array(Set(ids))
        return Parent.query(on: database)
            .filter(\.id, in: uniqueIDs)
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
    var storage: [Row<Child>]
    let parentID: String
    
    init(_ parentID: String) {
        self.storage = []
        self.parentID = parentID
    }
    
    func run(_ models: [Any], on database: Database) -> EventLoopFuture<Void> {
        let ids: [Parent.ID] = models
            .map { $0 as! Row<Parent> }
            .map { $0.id! }
        
        let uniqueIDs = Array(Set(ids))
        return Child.query(on: database)
            .filter(self.parentID, in: uniqueIDs)
            .all()
            .map { self.storage = $0 }
    }
    
    func get(id: Any) throws -> [Any] {
        let id = id as! Parent.ID
        return self.storage.filter { child in
            return child.get(self.parentID) == id
        }
    }
}
