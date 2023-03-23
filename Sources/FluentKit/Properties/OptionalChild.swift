import NIOCore

extension Model {
    public typealias OptionalChild<To> = OptionalChildProperty<Self, To>
        where To: FluentKit.Model
}

// MARK: Type

@propertyWrapper
public final class OptionalChildProperty<From, To>
    where From: Model, To: Model
{
    public typealias Key = RelationParentKey<From, To>

    public let parentKey: Key
    var idValue: From.IDValue?

    public var value: To??

    public convenience init(for parent: KeyPath<To, To.Parent<From>>) {
        self.init(for: .required(parent))
    }

    public convenience init(for optionalParent: KeyPath<To, To.OptionalParent<From>>) {
        self.init(for: .optional(optionalParent))
    }
    
    private init(for parentKey: Key) {
        self.parentKey = parentKey
    }

    public var wrappedValue: To? {
        get {
            guard let value = self.value else {
                fatalError("Child relation not eager loaded, use $ prefix to access: \(name)")
            }
            return value
        }
        set {
            fatalError("Child relation  \(self.name) is get-only.")
        }
    }

    public var projectedValue: OptionalChildProperty<From, To> {
        return self
    }
    
    public var fromId: From.IDValue? {
        get { return self.idValue }
        set { self.idValue = newValue }
    }

    public func query(on database: Database) -> QueryBuilder<To> {
        guard let id = self.idValue else {
            fatalError("Cannot query child relation \(self.name) from unsaved model.")
        }
        let builder = To.query(on: database)
        switch self.parentKey {
        case .optional(let optional):
            builder.filter(optional.appending(path: \.$id) == id)
        case .required(let required):
            builder.filter(required.appending(path: \.$id) == id)
        }
        return builder
    }

    public func create(_ to: To, on database: Database) -> EventLoopFuture<Void> {
        guard let id = self.idValue else {
            fatalError("Cannot save child in \(self.name) to unsaved model in.")
        }
        switch self.parentKey {
        case .required(let keyPath):
            to[keyPath: keyPath].id = id
        case .optional(let keyPath):
            to[keyPath: keyPath].id = id
        }
        return to.create(on: database)
    }
}

extension OptionalChildProperty: CustomStringConvertible {
    public var description: String {
        self.name
    }
}

// MARK: Property

extension OptionalChildProperty: AnyProperty { }

extension OptionalChildProperty: Property {
    public typealias Model = From
    public typealias Value = To?
}

// MARK: Database

extension OptionalChildProperty: AnyDatabaseProperty {
    public var keys: [FieldKey] {
        []
    }

    public func input(to input: DatabaseInput) {
        // child never has input
    }

    public func output(from output: DatabaseOutput) throws {
        let key = From()._$id.field.key
        if output.contains(key) {
            self.idValue = try output.decode(key, as: From.IDValue.self)
        }
    }
}

// MARK: Codable

extension OptionalChildProperty: AnyCodableProperty {
    public func encode(to encoder: Encoder) throws {
        if let child = self.value {
            var container = encoder.singleValueContainer()
            try container.encode(child)
        }
    }

    public func decode(from decoder: Decoder) throws {
        // don't decode
    }

    public var skipPropertyEncoding: Bool {
        self.value == nil // Avoids leaving an empty JSON object lying around in some cases.
    }
}

// MARK: Relation

extension OptionalChildProperty: Relation {
    public var name: String {
        "Child<\(From.self), \(To.self)>(for: \(self.parentKey))"
    }

    public func load(on database: Database) -> EventLoopFuture<Void> {
        self.query(on: database).first().map {
            self.value = $0
        }
    }
}

// MARK: Eager Loadable

extension OptionalChildProperty: EagerLoadable {
    public static func eagerLoad<Builder>(
        _ relationKey: KeyPath<From, OptionalChildProperty<From, To>>,
        to builder: Builder
    )
        where Builder : EagerLoadBuilder, From == Builder.Model
    {
        self.eagerLoad(relationKey, withDeleted: false, to: builder)
    }
    
    public static func eagerLoad<Builder>(
        _ relationKey: KeyPath<From, From.OptionalChild<To>>,
        withDeleted: Bool,
        to builder: Builder
    )
        where Builder: EagerLoadBuilder, Builder.Model == From
    {
        let loader = OptionalChildEagerLoader(relationKey: relationKey, withDeleted: withDeleted)
        builder.add(loader: loader)
    }


    public static func eagerLoad<Loader, Builder>(
        _ loader: Loader,
        through: KeyPath<From, From.OptionalChild<To>>,
        to builder: Builder
    ) where
        Loader: EagerLoader,
        Loader.Model == To,
        Builder: EagerLoadBuilder,
        Builder.Model == From
    {
        let loader = ThroughChildEagerLoader(relationKey: through, loader: loader)
        builder.add(loader: loader)
    }
}

private struct OptionalChildEagerLoader<From, To>: EagerLoader
    where From: Model, To: Model
{
    let relationKey: KeyPath<From, From.OptionalChild<To>>
    let withDeleted: Bool

    func run(models: [From], on database: Database) -> EventLoopFuture<Void> {
        let ids = models.compactMap { $0.id! }

        let builder = To.query(on: database)
        let parentKey = From()[keyPath: self.relationKey].parentKey
        switch parentKey {
        case .optional(let optional):
            builder.filter(optional.appending(path: \.$id) ~~ Set(ids))
        case .required(let required):
            builder.filter(required.appending(path: \.$id) ~~ Set(ids))
        }
        if (self.withDeleted) {
            builder.withDeleted()
        }
        return builder.all().map {
            for model in models {
                let id = model[keyPath: self.relationKey].idValue!
                let children = $0.filter { child in
                    switch parentKey {
                    case .optional(let optional):
                        return child[keyPath: optional].id == id
                    case .required(let required):
                        return child[keyPath: required].id == id
                    }
                }
                model[keyPath: self.relationKey].value = children.first
            }
        }
    }
}

private struct ThroughChildEagerLoader<From, Through, Loader>: EagerLoader
    where From: Model, Loader: EagerLoader, Loader.Model == Through
{
    let relationKey: KeyPath<From, From.OptionalChild<Through>>
    let loader: Loader

    func run(models: [From], on database: Database) -> EventLoopFuture<Void> {
        let throughs = models.compactMap {
            $0[keyPath: self.relationKey].value!
        }
        return self.loader.run(models: throughs, on: database)
    }
}
