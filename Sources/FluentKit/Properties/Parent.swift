extension Model {
    public typealias Parent<To> = ParentProperty<Self, To>
        where To: FluentKit.Model
}

// MARK: Type

@propertyWrapper
public final class ParentProperty<From, To>
    where From: Model, To: Model
{
    @FieldProperty<From, To.IDValue>
    public var id: To.IDValue

    public var wrappedValue: To {
        get {
            guard let value = self.value else {
                fatalError("Parent relation not eager loaded, use $ prefix to access: \(name)")
            }
            return value
        }
        set { fatalError("use $ prefix to access") }
    }

    public var projectedValue: ParentProperty<From, To> {
        return self
    }

    public var value: To?

    public init(key: FieldKey) {
        self._id = .init(key: key)
    }

    public func query(on database: Database) -> QueryBuilder<To> {
        return To.query(on: database)
            .filter(\._$id == self.id)
    }
}

extension ParentProperty: CustomStringConvertible {
    public var description: String {
        self.name
    }
}

// MARK: Relation

extension ParentProperty: Relation {
    public var name: String {
        "Parent<\(From.self), \(To.self)>(key: \(self.$id.key))"
    }

    public func load(on database: Database) -> EventLoopFuture<Void> {
        self.query(on: database).first().map {
            self.value = $0
        }
    }
}

// MARK: Property

extension ParentProperty: AnyProperty { }

extension ParentProperty: Property {
    public typealias Model = From
    public typealias Value = To
}

// MARK: Database

extension ParentProperty: AnyDatabaseProperty {
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

extension ParentProperty: AnyCodableProperty {
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

extension ParentProperty: EagerLoadable {
    public static func eagerLoad<Builder>(
        _ relationKey: KeyPath<From, From.Parent<To>>,
        to builder: Builder
    )
        where Builder: EagerLoadBuilder, Builder.Model == From
    {
        let loader = ParentEagerLoader(relationKey: relationKey)
        builder.add(loader: loader)
    }


    public static func eagerLoad<Loader, Builder>(
        _ loader: Loader,
        through: KeyPath<From, From.Parent<To>>,
        to builder: Builder
    ) where
        Loader: EagerLoader,
        Loader.Model == To,
        Builder: EagerLoadBuilder,
        Builder.Model == From
    {
        let loader = ThroughParentEagerLoader(relationKey: through, loader: loader)
        builder.add(loader: loader)
    }
}

private struct ParentEagerLoader<From, To>: EagerLoader
    where From: Model, To: Model
{
    let relationKey: KeyPath<From, From.Parent<To>>

    func run(models: [From], on database: Database) -> EventLoopFuture<Void> {
        let ids = models.map {
            $0[keyPath: self.relationKey].id
        }

        return To.query(on: database)
            .filter(\._$id ~~ Set(ids))
            .all()
            .flatMapThrowing
        {
            for model in models {
                guard let parent = $0.filter({
                    $0.id == model[keyPath: self.relationKey].id
                }).first else {
                    database.logger.debug("No parent '\(To.self)' with id '\(model[keyPath: self.relationKey].id)' was found in eager-load results.")
                    throw FluentError.missingParent
                }
                model[keyPath: self.relationKey].value = parent
            }
        }
    }
}

private struct ThroughParentEagerLoader<From, Through, Loader>: EagerLoader
    where From: Model, Loader: EagerLoader, Loader.Model == Through
{
    let relationKey: KeyPath<From, From.Parent<Through>>
    let loader: Loader

    func run(models: [From], on database: Database) -> EventLoopFuture<Void> {
        let throughs = models.map {
            $0[keyPath: self.relationKey].value!
        }
        return self.loader.run(models: throughs, on: database)
    }
}
