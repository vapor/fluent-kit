import NIOCore
import NIOConcurrencyHelpers

extension Model {
    public typealias Parent<To> = ParentProperty<Self, To>
        where To: FluentKit.Model
}

// MARK: Type

@propertyWrapper
public final class ParentProperty<From, To>: @unchecked Sendable
    where From: Model, To: Model
{
    @FieldProperty<From, To.IDValue>
    public var id: To.IDValue

    public var wrappedValue: To {
        get {
            guard let value = self.value else {
                fatalError("Parent relation not eager loaded, use $ prefix to access: \(self.name)")
            }
            return value
        }
        set { fatalError("use $ prefix to access \(self.name)") }
    }

    public var projectedValue: ParentProperty<From, To> {
        return self
    }

    let _value: NIOLockedValueBox<To?> = .init(nil)
    public var value: To? {
        get { self._value.withLockedValue { $0 } }
        set { self._value.withLockedValue { $0 = newValue } }
    }

    public init(key: FieldKey) {
        guard !(To.IDValue.self is any Fields.Type) else {
            fatalError("Can not use @Parent to target a model with composite ID; use @CompositeParent instead.")
        }
        
        self._id = .init(key: key)
    }

    public func query(on database: any Database) -> QueryBuilder<To> {
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

    public func load(on database: any Database) -> EventLoopFuture<Void> {
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

// MARK: Query-addressable

extension ParentProperty: AnyQueryAddressableProperty {
    public var anyQueryableProperty: any AnyQueryableProperty { self.$id.anyQueryableProperty }
    public var queryablePath: [FieldKey] { self.$id.queryablePath }
}

extension ParentProperty: QueryAddressableProperty {
    public var queryableProperty: FieldProperty<From, To.IDValue> { self.$id.queryableProperty }
}

// MARK: Database

extension ParentProperty: AnyDatabaseProperty {
    public var keys: [FieldKey] {
        self.$id.keys
    }
    
    public func input(to input: any DatabaseInput) {
        self.$id.input(to: input)
    }

    public func output(from output: any DatabaseOutput) throws {
        try self.$id.output(from: output)
    }
}

extension ParentProperty: AnyCodableProperty {
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        if let parent = self.value {
            try container.encode(parent)
        } else {
            try container.encode([
                "id": self.id
            ])
        }
    }

    public func decode(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: SomeCodingKey.self)
        try self.$id.decode(from: container.superDecoder(forKey: .init(stringValue: "id")))
    }
}

// MARK: Eager Loadable

extension ParentProperty: EagerLoadable {
    public static func eagerLoad<Builder>(
        _ relationKey: KeyPath<From, ParentProperty<From, To>>,
        to builder: Builder
    )
        where Builder : EagerLoadBuilder, From == Builder.Model
    {
        self.eagerLoad(relationKey, withDeleted: false, to: builder)
    }
    
    public static func eagerLoad<Builder>(
        _ relationKey: KeyPath<From, From.Parent<To>>,
        withDeleted: Bool,
        to builder: Builder
    )
        where Builder: EagerLoadBuilder, Builder.Model == From
    {
        let loader = ParentEagerLoader(relationKey: relationKey, withDeleted: withDeleted)
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
    where From: FluentKit.Model, To: FluentKit.Model
{
    let relationKey: KeyPath<From, ParentProperty<From, To>>
    let withDeleted: Bool

    func run(models: [From], on database: any Database) -> EventLoopFuture<Void> {
        let sets = UnsafeTransfer(wrappedValue: Dictionary(grouping: models, by: { $0[keyPath: self.relationKey].id }))
        let builder = To.query(on: database).filter(\._$id ~~ Set(sets.wrappedValue.keys))
        if (self.withDeleted) {
            builder.withDeleted()
        }
        return builder.all().flatMapThrowing {
            let parents = Dictionary(uniqueKeysWithValues: $0.map { ($0.id!, $0) })

            for (parentId, models) in sets.wrappedValue {
                guard let parent = parents[parentId] else {
                    database.logger.debug(
                        "Missing parent model in eager-load lookup results.",
                        metadata: ["parent": .string("\(To.self)"), "id": .string("\(parentId)")]
                    )
                    throw FluentError.missingParentError(keyPath: self.relationKey, id: parentId)
                }
                models.forEach { $0[keyPath: self.relationKey].value = parent }
            }
        }
    }
}

private struct ThroughParentEagerLoader<From, Through, Loader>: EagerLoader
    where From: Model, Loader: EagerLoader, Loader.Model == Through
{
    let relationKey: KeyPath<From, From.Parent<Through>>
    let loader: Loader

    func run(models: [From], on database: any Database) -> EventLoopFuture<Void> {
        let throughs = models.map {
            $0[keyPath: self.relationKey].value!
        }
        return self.loader.run(models: throughs, on: database)
    }
}
