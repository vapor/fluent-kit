import NIOCore

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
            fatalError("OptionalParent relation \(self.name) is get-only.")
        }
    }

    public var projectedValue: OptionalParentProperty<From, To> {
        return self
    }

    public var value: To??

    public init(key: FieldKey) {
        guard !(To.IDValue.self is Fields.Type) else {
            fatalError("Can not use @OptionalParent to target a model with composite ID; use @CompositeOptionalParent instead.")
        }

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

// MARK: Query-addressable

extension OptionalParentProperty: AnyQueryAddressableProperty {
    public var anyQueryableProperty: AnyQueryableProperty { self.$id.anyQueryableProperty }
    public var queryablePath: [FieldKey] { self.$id.queryablePath }
}

extension OptionalParentProperty: QueryAddressableProperty {
    public var queryableProperty: OptionalFieldProperty<From, To.IDValue> { self.$id.queryableProperty }
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
        if case .some(.some(let parent)) = self.value { // require truly non-nil so we don't mis-encode when value has been manually cleared
            try container.encode(parent)
        } else {
            try container.encode([
                "id": self.id
            ])
        }
    }

    public func decode(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: SomeCodingKey.self)
        try self.$id.decode(from: container.superDecoder(forKey: .init(stringValue: "id")))
    }
}

// MARK: Eager Loadable

extension OptionalParentProperty: EagerLoadable {
    public static func eagerLoad<Builder>(
        _ relationKey: KeyPath<From,
        OptionalParentProperty<From, To>>,
        to builder: Builder
    )
        where Builder : EagerLoadBuilder, From == Builder.Model
    {
        self.eagerLoad(relationKey, withDeleted: false, to: builder)
    }
    
    public static func eagerLoad<Builder>(
        _ relationKey: KeyPath<From, From.OptionalParent<To>>,
        withDeleted: Bool,
        to builder: Builder
    )
        where Builder: EagerLoadBuilder, Builder.Model == From
    {
        let loader = OptionalParentEagerLoader(relationKey: relationKey, withDeleted: withDeleted)
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
    where From: FluentKit.Model, To: FluentKit.Model
{
    let relationKey: KeyPath<From, OptionalParentProperty<From, To>>
    let withDeleted: Bool

    func run(models: [From], on database: Database) -> EventLoopFuture<Void> {
        var sets = Dictionary(grouping: models, by: { $0[keyPath: self.relationKey].id })
        let nilParentModels = sets.removeValue(forKey: nil) ?? []

        let builder = To.query(on: database).filter(\._$id ~~ Set(sets.keys.compactMap { $0 }))
        if (self.withDeleted) {
            builder.withDeleted()
        }
        return builder.all().flatMapThrowing {
            let parents = Dictionary(uniqueKeysWithValues: $0.map { ($0.id!, $0) })

            for (parentId, models) in sets {
                guard let parent = parents[parentId!] else {
                    database.logger.debug(
                        "Missing parent model in eager-load lookup results.",
                        metadata: ["parent": .string("\(To.self)"), "id": .string("\(parentId!)")]
                    )
                    throw FluentError.missingParentError(keyPath: self.relationKey, id: parentId!)
                }
                models.forEach { $0[keyPath: self.relationKey].value = .some(.some(parent)) }
            }
            nilParentModels.forEach { $0[keyPath: self.relationKey].value = .some(.none) }
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
