#warning("TODO: remove Anys from protocol")
public protocol EagerLoad: class {
    func run(_ models: [Any], on database: Database) -> EventLoopFuture<Void>
    func get(id: Any) throws -> [Any]
}

extension Row {
    public func joined<Joined>(_ model: Joined.Type) -> Row<Joined>
        where Joined: FluentKit.Model
    {
        return Row<Joined>(storage: DefaultModelStorage(
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
    
    func decode<T>(field: String, as type: T.Type) throws -> T where T : Decodable {
        return try self.wrapped.decode(field: self.prefix + field, as: T.self)
    }
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
            let parent = child.joined(Parent.self)
            try res[parent.get(\.id)] = parent
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
    
    let parentID: ModelField<Child, Parent.ID>
    
    init(_ parentID: ModelField<Child, Parent.ID>) {
        self.storage = []
        self.parentID = parentID
    }
    
    func run(_ models: [Any], on database: Database) -> EventLoopFuture<Void> {
        let ids: [Parent.ID] = try! models
            .map { $0 as! Row<Child> }
            .map { try $0.get(self.parentID) }

        let uniqueIDs = Array(Set(ids))
        return database.query(Parent.self)
            .filter(\.id, in: uniqueIDs)
            .all()
            .map { self.storage = $0 }
    }
    
    func get(id: Any) throws -> [Any] {
        let id = id as! Parent.ID
        return try self.storage.filter { parent in
            return try parent.get(\.id) == id
        }
    }
}

final class SubqueryChildEagerLoad<Parent, Child>: EagerLoad
    where Parent: Model, Child: Model
{
    var storage: [Row<Child>]
    
    let parentID: ModelField<Child, Parent.ID>
    
    init(_ parentID: ModelField<Child, Parent.ID>) {
        self.storage = []
        self.parentID = parentID
    }
    
    func run(_ models: [Any], on database: Database) -> EventLoopFuture<Void> {
        let ids: [Parent.ID] = try! models
            .map { $0 as! Row<Parent> }
            .map { try $0.get(\.id) }
        
        let uniqueIDs = Array(Set(ids))
        return database.query(Child.self)
            .filter(self.parentID, in: uniqueIDs)
            .all()
            .map { self.storage = $0 }
    }
    
    func get(id: Any) throws -> [Any] {
        let id = id as! Parent.ID
        return try self.storage.filter { child in
            return try child.get(self.parentID) == id
        }
    }
}
