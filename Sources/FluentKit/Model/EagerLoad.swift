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

public protocol RelationLoader: AnyRelationLoader {
    associatedtype Model: FluentKit.Model
    func run(models: [Model], on database: Database) -> EventLoopFuture<Void>
}

extension RelationLoader {
    func anyRun(models: [AnyModel], on database: Database) -> EventLoopFuture<Void> {
        self.run(models: models.map { $0 as! Model }, on: database)
    }
}

public protocol AnyRelationLoader {
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

struct ThroughChildrenRelationLoader<From, Through, Loader>: RelationLoader
    where From: Model, Loader: RelationLoader, Loader.Model == Through
{
    let relationKey: KeyPath<From, Children<From, Through>>
    let loader: Loader

    func run(models: [From], on database: Database) -> EventLoopFuture<Void> {
        let throughs = models.flatMap {
            $0[keyPath: self.relationKey].value!
        }
        return loader.run(models: throughs, on: database)
    }
}


public protocol RelationLoadable {
    associatedtype From: Model
    associatedtype To: Model

    static func load<Builder>(
        _ relationKey: KeyPath<From, Self>,
        to builder: Builder
    ) where Builder: EagerLoadBuilder, Builder.Model == From


    static func load<Loader, Builder>(
        _ loader: Loader,
        through: KeyPath<From, Self>,
        to builder: Builder
    ) where Loader: RelationLoader,
        Builder: EagerLoadBuilder,
        Loader.Model == To,
        Builder.Model == From
}

//extension Parent: RelationLoadable {
//    public static func load<Builder>(
//        _ relationKey: KeyPath<To, Parent<To>>,
//        to builder: Builder
//    )
//        where Builder: EagerLoadBuilder, Builder.Model == To
//    {
//        let loader = ParentRelationLoader(relationKey: relationKey)
//        builder.add(loader: loader)
//    }
//
//
//    public static func load<Loader, Builder>(
//        _ loader: Loader,
//        through: KeyPath<To, Parent<To>>,
//        to builder: Builder
//    ) where Loader: RelationLoader, Loader.Model == Base,
//        Builder: EagerLoadBuilder, Builder.Model == Base
//    {
//        let loader = ThroughParentRelationLoader(relationKey: through, loader: loader)
//        builder.add(loader: loader)
//    }
//}

extension Children: RelationLoadable {
    public static func load<Builder>(
        _ relationKey: KeyPath<From, Children<From, To>>,
        to builder: Builder
    )
        where Builder: EagerLoadBuilder, Builder.Model == From
    {
        let loader = ChildrenRelationLoader(relationKey: relationKey)
        builder.add(loader: loader)
    }


    public static func load<Loader, Builder>(
        _ loader: Loader,
        through: KeyPath<From, Children<From, To>>,
        to builder: Builder
    ) where
        Loader: RelationLoader,
        Loader.Model == To,
        Builder: EagerLoadBuilder,
        Builder.Model == From
    {
        let loader = ThroughChildrenRelationLoader(relationKey: through, loader: loader)
        builder.add(loader: loader)
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


public protocol EagerLoadBuilder {
    associatedtype Model: FluentKit.Model
    func add<Loader>(loader: Loader)
        where Loader: RelationLoader, Loader.Model == Model
}

public struct NestedEagerLoadBuilder<Builder, Relation>: EagerLoadBuilder
    where Builder: EagerLoadBuilder,
        Relation: RelationLoadable,
        Builder.Model == Relation.From
{
    public typealias Model = Relation.To
    let builder: Builder
    let relationKey: KeyPath<Relation.From, Relation>

    init(builder: Builder, _ relationKey: KeyPath<Relation.From, Relation>) {
        self.builder = builder
        self.relationKey = relationKey
    }

    public func add<Loader>(loader: Loader)
        where Loader: RelationLoader, Loader.Model == Relation.To
    {
        Relation.load(loader, through: self.relationKey, to: self.builder)
    }
}

extension QueryBuilder: EagerLoadBuilder {
    public func add<Loader>(loader: Loader)
        where Loader: RelationLoader, Loader.Model == Model
    {
        self.loaders.append(loader)
    }
}

extension EagerLoadBuilder {
    @discardableResult
    public func _with<Relation>(_ relationKey: KeyPath<Model, Relation>) -> Self
        where Relation: RelationLoadable, Relation.From == Model
    {
        Relation.load(relationKey, to: self)
        return self
    }

    @discardableResult
    public func _with<Relation>(
        _ throughKey: KeyPath<Model, Relation>,
        _ nested: (NestedEagerLoadBuilder<Self, Relation>) -> ()
    ) -> Self
        where Relation: RelationLoadable, Relation.From == Model
    {
        let builder = NestedEagerLoadBuilder<Self, Relation>(builder: self, throughKey)
        nested(builder)
        return self
    }
}

