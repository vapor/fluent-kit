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
    public func with<Relation>(_ relationKey: KeyPath<Model, Relation>, withDeleted: Bool = false) -> Self
        where Relation: EagerLoadable, Relation.From == Model
    {
        Relation.eagerLoad(relationKey, to: self, withDeleted: withDeleted)
        return self
    }

    @discardableResult
    public func with<Relation>(
        _ throughKey: KeyPath<Model, Relation>,
        withDeleted: Bool = false,
        _ nested: (NestedEagerLoadBuilder<Self, Relation>) -> ()
    ) -> Self
        where Relation: EagerLoadable, Relation.From == Model
    {
        Relation.eagerLoad(throughKey, to: self, withDeleted: withDeleted)
        let builder = NestedEagerLoadBuilder<Self, Relation>(builder: self, throughKey, withDeleted: withDeleted)
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
    let withDeleted: Bool

    init(builder: Builder, _ relationKey: KeyPath<Relation.From, Relation>, withDeleted: Bool) {
        self.builder = builder
        self.relationKey = relationKey
        self.withDeleted = withDeleted
    }

    public func add<Loader>(loader: Loader)
        where Loader: EagerLoader, Loader.Model == Relation.To
    {
        Relation.eagerLoad(loader, through: self.relationKey, to: self.builder, withDeleted: withDeleted)
    }
}
