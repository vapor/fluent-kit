extension Model {
    public typealias OptionalParent<To> = ModelOptionalParent<Self, To>
        where To: Model
}

@propertyWrapper
public final class ModelOptionalParent<From, To>
    where From: Model, To: Model
{
    @ModelField<From, To.IDValue?>
    public var id: To.IDValue?

    public var wrappedValue: To? {
        get {
            self.value
        }
        set {
            fatalError("OptionalParent relation is get-only.")
        }
    }

    public var projectedValue: ModelOptionalParent<From, To> {
        return self
    }

    public var value: To?

    public init(key: String) {
        self._id = .init(key: key)
    }

    public func query(on database: Database) -> QueryBuilder<To> {
        return To.query(on: database)
            .filter(\._$id == self.id)
    }
}

extension ModelOptionalParent: Relation {
    public var name: String {
        "OptionalParent<\(From.self), \(To.self)>(key: \(self.key))"
    }

    public func load(on database: Database) -> EventLoopFuture<Void> {
        self.query(on: database).first().map {
            self.value = $0
        }
    }
}

extension ModelOptionalParent: FieldRepresentable {
    public var field: ModelField<From, To.IDValue?> {
        return self.$id
    }
}

extension ModelOptionalParent: AnyProperty {
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        if let parent = self.value {
            try container.encode(parent)
        } else {
            try container.encode([
                To.key(for: \._$id): self.id
            ])
        }
    }

    func decode(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: ModelCodingKey.self)
        try self.$id.decode(from: container.superDecoder(forKey: .string(To.key(for: \._$id))))
        // TODO: allow for nested decoding
    }
}

extension ModelOptionalParent: AnyField { }

extension ModelOptionalParent: EagerLoadable {
    public static func eagerLoad<Builder>(
        _ relationKey: KeyPath<From, From.OptionalParent<To>>,
        to builder: Builder
    )
        where Builder: EagerLoadBuilder, Builder.Model == From
    {
        let loader = OptionalParentEagerLoader(relationKey: relationKey)
        builder.add(loader: loader)
    }


    public static func eagerLoad<Loader, Builder>(
        _ loader: Loader,
        through: KeyPath<From, From.OptionalParent<To>>,
        to builder: Builder
    ) where
        Loader: EagerLoader,
        Loader.Model == To,
        Builder: EagerLoadBuilder,
        Builder.Model == From
    {
        let loader = ThroughOptionalParentEagerLoader(relationKey: through, loader: loader)
        builder.add(loader: loader)
    }
}

private struct OptionalParentEagerLoader<From, To>: EagerLoader
    where From: Model, To: Model
{
    let relationKey: KeyPath<From, From.OptionalParent<To>>

    func run(models: [From], on database: Database) -> EventLoopFuture<Void> {
        let ids = models.map {
            $0[keyPath: self.relationKey].id
        }

        guard !ids.isEmpty else {
            return database.eventLoop.makeSucceededFuture(())
        }

        return To.query(on: database)
            .filter(\._$id ~~ Set(ids))
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

private struct ThroughOptionalParentEagerLoader<From, Through, Loader>: EagerLoader
    where From: Model, Loader: EagerLoader, Loader.Model == Through
{
    let relationKey: KeyPath<From, From.OptionalParent<Through>>
    let loader: Loader

    func run(models: [From], on database: Database) -> EventLoopFuture<Void> {
        let throughs = models.map {
            $0[keyPath: self.relationKey].value!
        }
        return self.loader.run(models: throughs, on: database)
    }
}
