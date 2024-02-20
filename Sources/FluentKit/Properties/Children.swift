import NIOCore

extension Model {
    public typealias Children<To> = ChildrenProperty<Self, To>
        where To: FluentKit.Model
}

// MARK: Type

@propertyWrapper
public final class ChildrenProperty<From, To>
    where From: Model, To: Model
{
    public typealias Key = RelationParentKey<From, To>

    public let parentKey: Key
    var idValue: From.IDValue?

    public var value: [To]?

    public convenience init(for parent: KeyPath<To, To.Parent<From>>) {
        self.init(for: .required(parent))
    }

    public convenience init(for optionalParent: KeyPath<To, To.OptionalParent<From>>) {
        self.init(for: .optional(optionalParent))
    }
    
    private init(for parentKey: Key) {
        self.parentKey = parentKey
    }

    public var wrappedValue: [To] {
        get {
            guard let value = self.value else {
                fatalError("Children relation not eager loaded, use $ prefix to access: \(self.name)")
            }
            return value
        }
        set {
            fatalError("Children relation \(self.name) is get-only.")
        }
    }

    public var projectedValue: ChildrenProperty<From, To> {
        return self
    }
    
    public var fromId: From.IDValue? {
        get { return self.idValue }
        set { self.idValue = newValue }
    }

    public func query(on database: Database) -> QueryBuilder<To> {
        guard let id = self.idValue else {
            fatalError("Cannot query children relation \(self.name) from unsaved model.")
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

    public func create(_ to: [To], on database: Database) -> EventLoopFuture<Void> {
        guard let id = self.idValue else {
            fatalError("Cannot save child in relation \(self.name) to unsaved model.")
        }
        to.forEach {
            switch self.parentKey {
            case .required(let keyPath):
                $0[keyPath: keyPath].id = id
            case .optional(let keyPath):
                $0[keyPath: keyPath].id = id
            }
        }
        return to.create(on: database)
    }

    public func create(_ to: To, on database: Database) -> EventLoopFuture<Void> {
        guard let id = self.idValue else {
            fatalError("Cannot save child in relation \(self.name) to unsaved model.")
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

extension ChildrenProperty: CustomStringConvertible {
    public var description: String {
        self.name
    }
}

// MARK: Property

extension ChildrenProperty: AnyProperty { }

extension ChildrenProperty: Property {
    public typealias Model = From
    public typealias Value = [To]
}

// MARK: Database

extension ChildrenProperty: AnyDatabaseProperty {
    public var keys: [FieldKey] {
        []
    }

    public func input(to input: DatabaseInput) {
        // children never has input
    }

    public func output(from output: DatabaseOutput) throws {
        let key = From()._$id.field.key
        if output.contains(key) {
            self.idValue = try output.decode(key, as: From.IDValue.self)
        }
    }
}

// MARK: Codable

extension ChildrenProperty: AnyCodableProperty {
    public func encode(to encoder: Encoder) throws {
        if let rows = self.value {
            var container = encoder.singleValueContainer()
            try container.encode(rows)
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

extension ChildrenProperty: Relation {
    public var name: String {
        "Children<\(From.self), \(To.self)>(for: \(self.parentKey))"
    }

    public func load(on database: Database) -> EventLoopFuture<Void> {
        self.query(on: database).all().map {
            self.value = $0
        }
    }
}

// MARK: Eager Loadable

extension ChildrenProperty: EagerLoadable {
    public static func eagerLoad<Builder>(
        _ relationKey: KeyPath<From, ChildrenProperty<From, To>>,
        to builder: Builder
    )
        where Builder : EagerLoadBuilder, From == Builder.Model
    {
        self.eagerLoad(relationKey, withDeleted: false, to: builder)
    }
    
    public static func eagerLoad<Builder>(
        _ relationKey: KeyPath<From, From.Children<To>>,
        withDeleted: Bool,
        to builder: Builder
    )
        where Builder: EagerLoadBuilder, Builder.Model == From
    {
        let loader = ChildrenEagerLoader(relationKey: relationKey, withDeleted: withDeleted)
        builder.add(loader: loader)
    }


    public static func eagerLoad<Loader, Builder>(
        _ loader: Loader,
        through: KeyPath<From, From.Children<To>>,
        to builder: Builder
    ) where
        Loader: EagerLoader,
        Loader.Model == To,
        Builder: EagerLoadBuilder,
        Builder.Model == From
    {
        let loader = ThroughChildrenEagerLoader(relationKey: through, loader: loader)
        builder.add(loader: loader)
    }
}

private struct ChildrenEagerLoader<From, To>: EagerLoader
    where From: Model, To: Model
{
    let relationKey: KeyPath<From, From.Children<To>>
    let withDeleted: Bool
    
    func run(models: [From], on database: Database) -> EventLoopFuture<Void> {
        let ids = models.map { $0.id! }

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
                model[keyPath: self.relationKey].value = $0.filter { child in
                    switch parentKey {
                    case .optional(let optional):
                        return child[keyPath: optional].id == id
                    case .required(let required):
                        return child[keyPath: required].id == id
                    }
                }
            }
        }
    }
}

private struct ThroughChildrenEagerLoader<From, Through, Loader>: EagerLoader
    where From: Model, Loader: EagerLoader, Loader.Model == Through
{
    let relationKey: KeyPath<From, From.Children<Through>>
    let loader: Loader

    func run(models: [From], on database: Database) -> EventLoopFuture<Void> {
        let throughs = models.flatMap {
            $0[keyPath: self.relationKey].value!
        }
        return self.loader.run(models: throughs, on: database)
    }
}
