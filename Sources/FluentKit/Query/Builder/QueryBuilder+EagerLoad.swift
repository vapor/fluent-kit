extension QueryBuilder: EagerLoadBuilder {
    public func add<Loader>(loader: Loader)
        where Loader: EagerLoader, Loader.Model == Model
    {
        self.eagerLoaders.append(loader)
    }
}

public protocol EagerLoadBuilder {
    associatedtype Model: FluentKit.Model
    func add<Loader>(loader: Loader)
        where Loader: EagerLoader, Loader.Model == Model
}


extension EagerLoadBuilder {
    // MARK: Eager Load

    @discardableResult
    public func with<Relation>(_ relationKey: KeyPath<Model, Relation>) -> Self
        where Relation: EagerLoadable, Relation.From == Model
    {
        Relation.eagerLoad(relationKey, to: self)
        return self
    }

    @discardableResult
    public func with<Relation>(
        _ throughKey: KeyPath<Model, Relation>,
        _ nested: (NestedEagerLoadBuilder<Self, Relation>) -> ()
    ) -> Self
        where Relation: EagerLoadable, Relation.From == Model
    {
        Relation.eagerLoad(throughKey, to: self)
        let builder = NestedEagerLoadBuilder<Self, Relation>(builder: self, throughKey)
        nested(builder)
        return self
    }
    
    @discardableResult
    public func with<Relation>(
        _ relationKey: KeyPath<Model, Relation>,
        withDeleted: Bool
    ) -> Self
        where Relation: EagerLoadable, Relation.From == Model
    {
        Relation.eagerLoad(relationKey, withDeleted: withDeleted, to: self)
        return self
    }

    @discardableResult
    public func with<Relation>(
        _ throughKey: KeyPath<Model, Relation>,
        withDeleted: Bool,
        _ nested: (NestedEagerLoadBuilder<Self, Relation>) -> ()
    ) -> Self
        where Relation: EagerLoadable, Relation.From == Model
    {
        Relation.eagerLoad(throughKey, withDeleted: withDeleted, to: self)
        let builder = NestedEagerLoadBuilder<Self, Relation>(builder: self, throughKey)
        nested(builder)
        return self
    }
}

public struct NestedEagerLoadBuilder<Builder, Relation>: EagerLoadBuilder
    where Builder: EagerLoadBuilder,
        Relation: EagerLoadable,
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
        where Loader: EagerLoader, Loader.Model == Relation.To
    {
        Relation.eagerLoad(loader, through: self.relationKey, to: self.builder)
    }
}
