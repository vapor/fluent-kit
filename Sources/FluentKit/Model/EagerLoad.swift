#warning("TODO: remove Anys from protocol or make internal")
protocol EagerLoad: class {
    func run(_ models: [Any], on database: Database) -> EventLoopFuture<Void>
    func get(id: Any) throws -> [Any]
}

extension ModelRow {
    public func joined<Joined>(_ model: Joined.Type) throws -> Joined.Row
        where Joined: FluentKit.Model
    {
        return try Joined.Row(storage: DefaultModelStorage(
            output: self.storage.output!.prefixed(by: Joined.entity + "_"),
            eagerLoads: [:],
            exists: true
        ))
    }
}

extension DatabaseOutput {
    func prefixed(by string: String) -> DatabaseOutput {
        return PrefixingOutput(self, prefix: string)
    }
}

struct PrefixingOutput: DatabaseOutput {
    let wrapped: DatabaseOutput
    
    let prefix: String
    
    var description: String {
        return self.wrapped.description
    }
    
    init(_ wrapped: DatabaseOutput, prefix: String) {
        self.wrapped = wrapped
        self.prefix = prefix
    }

    func contains(field: String) -> Bool {
        return self.wrapped.contains(field: self.prefix + field)
    }
    
    func decode<T>(field: String, as type: T.Type) throws -> T where T : Decodable {
        return try self.wrapped.decode(field: self.prefix + field, as: T.self)
    }
}

final class JoinParentEagerLoad<Child, Parent>: EagerLoad
    where Child: Model, Parent: Model
{
    var parents: [Parent.ID: Parent.Row]
    
    init() {
        self.parents = [:]
    }
    
    func run(_ models: [Any], on database: Database) -> EventLoopFuture<Void> {
        var res: [Parent.ID: Parent.Row] = [:]
        try! models.map { $0 as! Child.Row }.forEach { child in
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
    var storage: [Parent.Row]
    
    let parentID: ModelField<Child, Parent.ID>
    
    init(_ parentID: ModelField<Child, Parent.ID>) {
        self.storage = []
        self.parentID = parentID
    }
    
    func run(_ models: [Any], on database: Database) -> EventLoopFuture<Void> {
        let ids: [Parent.ID] = models
            .map { $0 as! Child.Row }
            .map { $0.get(self.parentID) }

        let uniqueIDs = Array(Set(ids))
        return database.query(Parent.self)
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
    var storage: [Child.Row]
    
    let parentID: ModelField<Child, Parent.ID>
    
    init(_ parentID: ModelField<Child, Parent.ID>) {
        self.storage = []
        self.parentID = parentID
    }
    
    func run(_ models: [Any], on database: Database) -> EventLoopFuture<Void> {
        let ids: [Parent.ID] = models
            .map { $0 as! Parent.Row }
            .map { $0.id! }
        
        let uniqueIDs = Array(Set(ids))
        return database.query(Child.self)
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
