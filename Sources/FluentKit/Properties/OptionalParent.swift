extension Model {
    public typealias OptionalParent<To> = OptionalParentProperty<Self, To>
        where To: Model
}

// MARK: Type

@propertyWrapper
public final class OptionalParentProperty<From, To>
    where From: Model, To: Model
{
    @OptionalFieldProperty<From, To.IDValue>
    public var id: To.IDValue?

    public var wrappedValue: To? {
        get {
            self.value ?? nil
        }
        set {
            fatalError("OptionalParent relation is get-only.")
        }
    }

    public var projectedValue: OptionalParentProperty<From, To> {
        return self
    }

    public var value: To??

    public init(key: FieldKey) {
        self._id = .init(key: key)
    }

    public func query(on database: Database) -> QueryBuilder<To> {
        let builder = To.query(on: database)
        if let id = self.id {
            builder.filter(\._$id == id)
        } else {
            builder.filter(\._$id == .null)
        }
        return builder
    }
}

extension OptionalParentProperty: CustomStringConvertible {
    public var description: String {
        self.name
    }
}

// MARK: Relation

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

// MARK: Property

extension OptionalParentProperty: AnyProperty { }

extension OptionalParentProperty: Property {
    public typealias Model = From
    public typealias Value = To?
}

// MARK: Database

extension OptionalParentProperty: AnyDatabaseProperty {
    public var keys: [FieldKey] {
        self.$id.keys
    }
    
    public func input(to input: DatabaseInput) {
        self.$id.input(to: input)
    }

    public func output(from output: DatabaseOutput) throws {
        try self.$id.output(from: output)
    }
}

// MARK: Codable

extension OptionalParentProperty: AnyCodableProperty {
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
    }
}

// MARK: Eager Loadable

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
        
        return To.query(on: database)
            .filter(\._$id ~~ Set(ids))
            .all()
            .map
        {
            for model in models {
                model[keyPath: self.relationKey].value = .some($0.filter {
                    $0.id == model[keyPath: self.relationKey].id
                }.first)
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
        let throughs = models.compactMap {
            $0[keyPath: self.relationKey].value!
        }
        return self.loader.run(models: throughs, on: database)
    }
}
