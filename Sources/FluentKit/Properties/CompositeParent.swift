extension Model {
    public typealias CompositeParent<To> = CompositeParentProperty<Self, To>
        where To: Model, To.IDValue: Fields
}

@propertyWrapper @dynamicMemberLookup
public final class CompositeParentProperty<From, To>
    where From: Model, To: Model, To.IDValue: Fields
{
    public let prefix: FieldKey
    public let prefixingStrategy: KeyPrefixingStrategy
    public var id: To.IDValue
    public var value: To?

    public var wrappedValue: To {
        get {
            guard let value = self.value else {
                fatalError("Parent relation not eager loaded, use $ prefix to access: \(self.name)")
            }
            return value
        }
        set { fatalError("use $ prefix to access \(self.name)") }
    }

    public var projectedValue: CompositeParentProperty<From, To> { self }

    public init(prefix: FieldKey, prefixingStrategy: KeyPrefixingStrategy = .snakeCase) {
        self.id = .init()
        self.prefix = prefix
        self.prefixingStrategy = prefixingStrategy
    }

    public func query(on database: Database) -> QueryBuilder<To> {
        To.query(on: database)
            .filter(id: self.id)
    }

    public subscript<Nested>(dynamicMember keyPath: KeyPath<To.IDValue, Nested>) -> Nested
        where Nested: Property
    {
        self.id[keyPath: keyPath]
    }
}

extension CompositeParentProperty: CustomStringConvertible {
    public var description: String {
        self.name
    }
}

extension CompositeParentProperty: Relation {
    public var name: String {
        "CompositeParent<\(From.self), \(To.self)>(prefix: \(self.prefix), strategy: \(self.prefixingStrategy))"
    }
    
    public func load(on database: Database) -> EventLoopFuture<Void> {
        self.query(on: database)
            .first()
            .map {
                self.value = $0
            }
    }
}

extension CompositeParentProperty: AnyProperty {}

extension CompositeParentProperty: Property {
    public typealias Model = From
    public typealias Value = To
}

extension CompositeParentProperty: AnyDatabaseProperty {
    public var keys: [FieldKey] {
        To.IDValue.keys.map {
            self.prefixingStrategy.apply(prefix: self.prefix, to: $0)
        }
    }
    
    public func input(to input: DatabaseInput) {
        self.id.input(to: input.prefixed(by: self.prefix, using: self.prefixingStrategy))
    }
    
    public func output(from output: DatabaseOutput) throws {
        try self.id.output(from: output.prefixed(by: self.prefix, using: self.prefixingStrategy))
    }
}

extension CompositeParentProperty: AnyCodableProperty {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        if let value = self.value {
            try container.encode(value)
        } else {
            try container.encode(self.id)
        }
    }

    public func decode(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        self.id = try container.decode(To.IDValue.self)
    }
}

extension CompositeParentProperty: EagerLoadable {
    public static func eagerLoad<Builder>(_ relationKey: KeyPath<From, From.CompositeParent<To>>, to builder: Builder)
        where Builder: EagerLoadBuilder, Builder.Model == From
    {
        builder.add(loader: CompositeParentEagerLoader(relationKey: relationKey))
    }

    public static func eagerLoad<Loader, Builder>(_ loader: Loader, through: KeyPath<From, From.CompositeParent<To>>, to builder: Builder)
        where Loader: EagerLoader, Loader.Model == To, Builder: EagerLoadBuilder, Builder.Model == From
    {
        builder.add(loader: ThroughCompositeParentEagerLoader(relationKey: through, loader: loader))
    }
}

private struct CompositeParentEagerLoader<From, To>: EagerLoader
    where From: Model, To: Model, To.IDValue: Fields
{
    let relationKey: KeyPath<From, From.CompositeParent<To>>
    
    func run(models: [From], on database: Database) -> EventLoopFuture<Void> {
        let sets = Dictionary(grouping: models, by: { $0[keyPath: self.relationKey].id })

        return To.query(on: database)
            .group(.or) {
                _ = sets.keys.map($0.filter(id:))
            }
            .all()
            .flatMapThrowing {
                let parents = Dictionary(uniqueKeysWithValues: $0.map { ($0.id!, $0) })

                for (parentId, models) in sets {
                    guard let parent = parents[parentId] else {
                        database.logger.debug(
                            "Missing parent model in eager-load lookup results.",
                            metadata: ["parent": "\(To.self)", "id": "\(parentId)"]
                        )
                        throw FluentError.missingParentError(keyPath: self.relationKey, id: parentId)
                    }
                    models.forEach {
                        $0[keyPath: self.relationKey].value = parent
                    }
                }
            }
    }
}

private struct ThroughCompositeParentEagerLoader<From, Through, Loader>: EagerLoader
    where From: Model, Loader: EagerLoader, Loader.Model == Through, Through.IDValue: Fields
{
    let relationKey: KeyPath<From, From.CompositeParent<Through>>
    let loader: Loader
    
    func run(models: [From], on database: Database) -> EventLoopFuture<Void> {
        self.loader.run(models: models.map {
            $0[keyPath: self.relationKey].value!
        }, on: database)
    }
}
