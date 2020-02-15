extension Model {
    public typealias Children<To> = ModelChildren<Self, To>
        where To: FluentKit.Model
}

@propertyWrapper
public final class ModelChildren<From, To>: AnyProperty
    where From: Model, To: Model
{
    // MARK: ID

    enum Key {
        case required(KeyPath<To, To.Parent<From>>)
        case optional(KeyPath<To, To.OptionalParent<From>>)
    }

    let parentKey: Key
    var idValue: From.IDValue?

    // MARK: Wrapper
    public var value: [To]?

    public var description: String {
        self.idValue.debugDescription
    }

    public init(for parent: KeyPath<To, To.Parent<From>>) {
        self.parentKey = .required(parent)
    }

    public init(for optionalParent: KeyPath<To, To.OptionalParent<From>>) {
        self.parentKey = .optional(optionalParent)
    }

    public var wrappedValue: [To] {
        get {
            guard let value = self.value else {
                fatalError("Children relation not loaded.")
            }
            return value
        }
        set {
            fatalError("Children relation is get-only.")
        }
    }

    public var projectedValue: ModelChildren<From, To> {
        return self
    }
    
    public var fromId: From.IDValue? {
        return self.idValue
    }

    // MARK: Query

    public func query(on database: Database) -> QueryBuilder<To> {
        guard let id = self.idValue else {
            fatalError("Cannot query children relation from unsaved model.")
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
            fatalError("Cannot save child to unsaved model.")
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
            fatalError("Cannot save child to unsaved model.")
        }
        switch self.parentKey {
        case .required(let keyPath):
            to[keyPath: keyPath].id = id
        case .optional(let keyPath):
            to[keyPath: keyPath].id = id
        }
        return to.create(on: database)
    }

    // MARK: Property

    func output(from output: DatabaseOutput) throws {
        let key = From.key(for: \._$id)
        if output.contains(key) {
            self.idValue = try output.decode(key, as: From.IDValue.self)
        }
    }

    // MARK: Codable
    func encode(to encoder: Encoder) throws {
        if let rows = self.value {
            var container = encoder.singleValueContainer()
            try container.encode(rows)
        }
    }

    func decode(from decoder: Decoder) throws {
        // don't decode
    }
}

extension ModelChildren.Key: CustomStringConvertible {
    var description: String {
        switch self {
        case .optional(let keyPath):
            return To.key(for: keyPath)
        case .required(let keyPath):
            return To.key(for: keyPath)
        }
    }
}

extension ModelChildren: Relation {
    public var name: String {
        "Children<\(From.self), \(To.self)>(for: \(self.parentKey))"
    }

    public func load(on database: Database) -> EventLoopFuture<Void> {
        self.query(on: database).all().map {
            self.value = $0
        }
    }
}

extension ModelChildren: EagerLoadable {
    public static func eagerLoad<Builder>(
        _ relationKey: KeyPath<From, From.Children<To>>,
        to builder: Builder
    )
        where Builder: EagerLoadBuilder, Builder.Model == From
    {
        let loader = ChildrenEagerLoader(relationKey: relationKey)
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
