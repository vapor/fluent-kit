extension Model {
    public typealias OptionalParent<To> = OptionalParentProperty<Self, To>
        where To: Model
}

@propertyWrapper
public final class OptionalParentProperty<From, To>
    where From: Model, To: Model
{
    @FieldProperty<From, To.IDValue?>
    public var id: To.IDValue?

    public var wrappedValue: To? {
        get {
            self.value
        }
        set {
            fatalError("OptionalParent relation is get-only.")
        }
    }

    public var projectedValue: OptionalParentProperty<From, To> {
        return self
    }

    public var value: To?

    public init(key: FieldKey) {
        self._id = .init(key: key)
    }

    public func query(on database: Database) -> QueryBuilder<To> {
        To.query(on: database)
            .filter(\._$id == self.id!)
    }
}

extension OptionalParentProperty: Relation {
    public var name: String {
        "OptionalParent<\(From.self), \(To.self)>(key: \(self.$id.key))"
    }

    public func load(on database: Database) -> EventLoopFuture<Void> {
        self.query(on: database).first().map {
            self.value = $0
        }
    }
}

extension OptionalParentProperty: PropertyProtocol {
    public typealias Model = From
    public typealias Value = To
}

extension OptionalParentProperty: AnyProperty {
    public var nested: [AnyProperty] {
        [self.$id]
    }

    public var path: [FieldKey] {
        []
    }
    
    public func input(to input: inout DatabaseInput) {
        self.$id.input(to: &input)
    }

    public func output(from output: DatabaseOutput) throws {
        try self.$id.output(from: output)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        if let parent = self.value {
            try container.encode(parent)
        } else {
            try container.encode([
                "id": self.id
            ])
        }
    }

    public func decode(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: ModelCodingKey.self)
        try self.$id.decode(from: container.superDecoder(forKey: .string("id")))
        // TODO: allow for nested decoding
    }
}

extension OptionalParentProperty: EagerLoadable {
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
        let ids = models.compactMap {
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
