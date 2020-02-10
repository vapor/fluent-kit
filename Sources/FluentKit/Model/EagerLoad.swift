protocol EagerLoadRequest: class, CustomStringConvertible {
    func prepare(query: inout DatabaseQuery)
    func run(models: [AnyModel], on database: Database) -> EventLoopFuture<Void>
}

final class EagerLoads: CustomStringConvertible {
    var requests: [String: EagerLoadRequest]

    var description: String {
        return self.requests.description
    }

    init() {
        self.requests = [:]
    }
}

protocol RelationLoader: AnyRelationLoader {
    associatedtype Model: FluentKit.Model
    func run(models: [Model], on database: Database) -> EventLoopFuture<Void>
}

extension RelationLoader {
    func anyRun(models: [AnyModel], on database: Database) -> EventLoopFuture<Void> {
        self.run(models: models.map { $0 as! Model }, on: database)
    }
}

protocol AnyRelationLoader {
    func anyRun(models: [AnyModel], on database: Database) -> EventLoopFuture<Void>
}

struct ParentRelationLoader<From, To>: RelationLoader
    where From: Model, To: Model
{
    let relationKey: KeyPath<From, Parent<To>>

    func run(models: [From], on database: Database) -> EventLoopFuture<Void> {
        let ids = models.map {
            $0[keyPath: self.relationKey].id
        }

        guard !ids.isEmpty else {
            return database.eventLoop.makeSucceededFuture(())
        }

        return To.query(on: database)
            .filter(To.key(for: \._$id), in: Set(ids))
            .all()
            .map
        {
            for model in models {
                model[keyPath: self.relationKey].value = $0.filter {
                    $0.id == model[keyPath: self.relationKey].id
                }.first
            }
        }
    }
}

struct ThroughParentRelationLoader<From, Through, Loader>: RelationLoader
    where From: Model, Loader: RelationLoader, Loader.Model == Through
{
    let relationKey: KeyPath<From, Parent<Through>>
    let loader: Loader

    func run(models: [From], on database: Database) -> EventLoopFuture<Void> {
        let throughs = models.map {
            $0[keyPath: self.relationKey].value!
        }
        return loader.run(models: throughs, on: database)
    }
}


public protocol RelationLoadable {
    associatedtype Base: Model
    static func load(_ relationKey: KeyPath<Base, Self>, to builder: QueryBuilder<Base>)
}

extension Parent: RelationLoadable {
    public static func load(
        _ relationKey: KeyPath<To, Parent<To>>,
        to builder: QueryBuilder<To>
    ) {
        let loader = ParentRelationLoader(relationKey: relationKey)
        builder.loaders.append(loader)
    }
}

extension Children: RelationLoadable {
    public static func load(
        _ relationKey: KeyPath<From, Children<From, To>>,
        to builder: QueryBuilder<From>
    ) {
        let loader = ChildrenRelationLoader(relationKey: relationKey)
        builder.loaders.append(loader)
    }
}

struct ChildrenRelationLoader<From, To>: RelationLoader
    where From: Model, To: Model
{
    let relationKey: KeyPath<From, Children<From, To>>

    func run(models: [From], on database: Database) -> EventLoopFuture<Void> {
        let ids = models.map { $0.id! }

        let builder = To.query(on: database)
        let parentKey = From()[keyPath: self.relationKey].parentKey
        switch parentKey {
        case .optional(let optional):
            builder.filter(optional.appending(path: \.$id), in: Set(ids))
        case .required(let required):
            builder.filter(required.appending(path: \.$id), in: Set(ids))
        }
        return builder.all().map {
            for model in models {
                let id = model[keyPath: self.relationKey].idValue!
                model[keyPath: self.relationKey].value = $0.filter { child in
                    switch parentKey {
                    case .optional(let optional):
                        return child[keyPath: optional].id == id
                    case .required(let required):
                        return child[keyPath: required].id == id
                    }
                }
            }
        }
    }
}

extension QueryBuilder {
    public func _with<Relation>(_ relationKey: KeyPath<Model, Relation>) -> Self
        where Relation: RelationLoadable, Relation.Base == Model
    {
        Relation.load(relationKey, to: self)
        return self
    }

    public func _with<Through, To>(
        _ throughKey: KeyPath<Model, Parent<Through>>,
        _ relationKey: KeyPath<Through, Children<Through, To>>
    ) -> Self {
        let loader = ChildrenRelationLoader(relationKey: relationKey)
        let main = ThroughParentRelationLoader(relationKey: throughKey, loader: loader)
        self.loaders.append(main)
        return self
    }
}
