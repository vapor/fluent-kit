#warning("TODO: remove Anys from protocol")
public protocol EagerLoad: class {
    func run(_ models: [Any], on database: Database) -> EventLoopFuture<Void>
    func get(id: Any) throws -> [Any]
}

extension Model {
    public func joined<Joined>(_ model: Joined.Type) throws -> Joined
        where Joined: FluentKit.Model
    {
        return try Joined.init(loading: DefaultModelStorage(
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
    var parents: [Parent.ID: Parent]

    init() {
        self.parents = [:]
    }

    func run(_ models: [Any], on database: Database) -> EventLoopFuture<Void> {
        var res: [Parent.ID: Parent] = [:]
        try! models.map { $0 as! Child }.forEach { child in
            let parent = try child.joined(Parent.self)
            res[parent.id.value] = parent
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
    let parentID: ModelField<Child, Parent.ID>

    init(_ parentID: ModelField<Child, Parent.ID>) {
        self.storage = []
        self.parentID = parentID
    }
    
    func run(_ models: [Any], on database: Database) -> EventLoopFuture<Void> {
        let ids: [Parent.ID] = models
            .map { $0 as! Child }
            .map { try! $0.storage.output!.decode(field: self.parentID.name, as: Parent.ID.self) }

        let uniqueIDs = Array(Set(ids))
        return database.query(Parent.self)
            .filter(\.id, in: uniqueIDs)
            .all()
            .map { self.storage = $0 }
    }
    
    func get(id: Any) -> [Any] {
        let id = id as! Parent.ID
        return self.storage.filter { parent in
            return parent.id.value == id
        }
    }
}

final class SubqueryChildEagerLoad<Parent, Child>: EagerLoad
    where Parent: Model, Child: Model
{
    var storage: [Child]
    let parentID: ModelField<Child, Parent.ID>
    
    init(_ parentID: ModelField<Child, Parent.ID>) {
        self.storage = []
        self.parentID = parentID
    }
    
    func run(_ models: [Any], on database: Database) -> EventLoopFuture<Void> {
        let ids: [Parent.ID] = models
            .map { $0 as! Parent }
            .map { $0.id.value }
        
        let uniqueIDs = Array(Set(ids))
        return database.query(Child.self)
            .filter(self.parentID, in: uniqueIDs)
            .all()
            .map { self.storage = $0 }
    }
    
    func get(id: Any) throws -> [Any] {
        print("GET")
        let id = id as! Parent.ID
        print(self.storage)
        print(id)
        return try self.storage.filter { child in
            try self.parentID.load(from: child.storage)
            return self.parentID.value == id
        }
    }
}
