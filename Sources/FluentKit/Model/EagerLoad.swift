#warning("TODO: remove Anys from protocol")
public protocol EagerLoad: class {
    func run(_ models: [Any], on database: Database) -> EventLoopFuture<Void>
    func setup(_ root: Any)
    func get(id: Any) -> [Any]
}

//extension ModelRow {
//    public func joined<Joined>(_ model: Joined.Type) -> Joined.Row
//        where Joined: FluentKit.Model
//    {
//        return Joined.Row(storage: DefaultModelStorage(
//            output: self.storage.output!.prefixed(by: Joined.entity + "_"),
//            eagerLoads: [:],
//            exists: true
//        ))
//    }
//}

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

//final class JoinParentEagerLoad<Child, Parent>: EagerLoad
//    where Child: Model, Parent: Model
//{
//    var parents: [Parent.ID: Parent]
//
//    init() {
//        self.parents = [:]
//    }
//
//    func run(_ models: [Any], on database: Database) -> EventLoopFuture<Void> {
//        var res: [Parent.ID: Parent] = [:]
//        try! models.map { $0 as! Child }.forEach { child in
//            let parent = child.joined(Parent.self)
//            try res[parent.get(\.id)] = parent
//        }
//
//        self.parents = res
//        return database.eventLoop.makeSucceededFuture(())
//    }
//
//    func get(id: Any) throws -> [Any] {
//        let id = id as! Parent.ID
//        return [self.parents[id]!]
//    }
//}

final class SubqueryParentEagerLoad<Child, Parent>: EagerLoad
    where  Child: Model, Parent: Model
{
    var storage: [Parent]
    
    let parentID: KeyPath<Parent,
        KeyPath<Child, ModelField<Child, Parent.ID>>
    >

    var childID: KeyPath<Child, ModelField<Child, Parent.ID>>!
    
    init(_ parentID: KeyPath<Parent,
        KeyPath<Child, ModelField<Child, Parent.ID>>
    >) {
        self.storage = []
        self.parentID = parentID
    }

    func setup(_ root: Any) {
        self.childID = (root as! Parent)[keyPath: self.parentID]
    }
    
    func run(_ models: [Any], on database: Database) -> EventLoopFuture<Void> {
        let ids: [Parent.ID] = models
            .map { $0 as! Child }
            .map { $0[keyPath: self.childID].value }

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
    
    let parentID: KeyPath<Parent,
        KeyPath<Child, ModelField<Child, Parent.ID>>
    >

    var childID: KeyPath<Child, ModelField<Child, Parent.ID>>!
    
    init(_ parentID: KeyPath<Parent,
        KeyPath<Child, ModelField<Child, Parent.ID>>
    >) {
        self.storage = []
        self.parentID = parentID
    }

    func setup(_ root: Any) {
        self.childID = (root as! Parent)[keyPath: self.parentID]
    }
    
    func run(_ models: [Any], on database: Database) -> EventLoopFuture<Void> {
        let ids: [Parent.ID] = models
            .map { $0 as! Parent }
            .map { $0.id.value }
        
        let uniqueIDs = Array(Set(ids))
        return database.query(Child.self)
            .filter(self.childID, in: uniqueIDs)
            .all()
            .map { self.storage = $0 }
    }
    
    func get(id: Any) -> [Any] {
        let id = id as! Parent.ID
        return self.storage.filter { child in
            return child[keyPath: self.childID].value == id
        }
    }
}
