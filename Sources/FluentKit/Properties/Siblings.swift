extension Model {
    public typealias Siblings<To, Through> = ModelSiblings<Self, To, Through>
        where To: Model, Through: Model
}

@propertyWrapper
public final class ModelSiblings<From, To, Through>: AnyProperty
    where From: Model, To: Model, Through: Model
{
    public enum AttachMethod {
        // always create the pivot
        case always

        // only create the pivot if it doesn't already exist
        case ifNotExists
    }

    let from: KeyPath<Through, Through.Parent<From>>
    let to: KeyPath<Through, Through.Parent<To>>
    var idValue: From.IDValue?
    
    public var value: [To]?

    public init(
        through: Through.Type,
        from: KeyPath<Through, Through.Parent<From>>,
        to: KeyPath<Through, Through.Parent<To>>
    ) {
        self.from = from
        self.to = to
    }

    public var wrappedValue: [To] {
        get {
            guard let value = self.value else {
                fatalError("Siblings relation not loaded.")
            }
            return value
        }
        set {
            fatalError("Siblings relation is get-only.")
        }
    }

    public var projectedValue: ModelSiblings<From, To, Through> {
        return self
    }

    // MARK: Checking state

    public func isAttached(to: To, on database: Database) -> EventLoopFuture<Bool> {
        guard let toID = to.id else {
            fatalError("Cannot attach unsaved model.")
        }

        return self.isAttached(toID: toID, on: database)
    }

    public func isAttached(toID: To.IDValue, on database: Database) -> EventLoopFuture<Bool> {
        guard let fromID = self.idValue else {
            fatalError("Cannot check if siblings are attached to an unsaved model.")
        }

        return Through.query(on: database)
            .filter(self.from.appending(path: \.$id) == fromID)
            .filter(self.to.appending(path: \.$id) == toID)
            .first()
            .map { $0 != nil }
    }

    // MARK: Operations

    public func attach(
        _ tos: [To],
        on database: Database,
        _ edit: (Through) -> () = { _ in }
    ) -> EventLoopFuture<Void> {
        guard let fromID = self.idValue else {
            fatalError("Cannot attach siblings relation to unsaved model.")
        }

        return tos.map { to -> Through in
            guard let toID = to.id else {
                fatalError("Cannot attach unsaved model.")
            }
            let pivot = Through()
            pivot[keyPath: self.from].id = fromID
            pivot[keyPath: self.to].id = toID
            edit(pivot)
            return pivot
        }.create(on: database)
    }

    public func attach(
        _ to: To,
        method: AttachMethod,
        on database: Database,
        _ edit: @escaping (Through) -> () = { _ in }
    ) -> EventLoopFuture<Void> {
        switch method {
        case .always:
            return self.attach(to, on: database, edit)
        case .ifNotExists:
            return self.isAttached(to: to, on: database).flatMap { alreadyAttached in
                if alreadyAttached {
                    return database.eventLoop.makeSucceededFuture(())
                }

                return self.attach(to, on: database, edit)
            }
        }
    }

    public func attach(
        _ to: To,
        on database: Database,
        _ edit: (Through) -> () = { _ in }
    ) -> EventLoopFuture<Void> {
        guard let fromID = self.idValue else {
            fatalError("Cannot attach siblings relation to unsaved model.")
        }
        guard let toID = to.id else {
            fatalError("Cannot attach unsaved model.")
        }

        let pivot = Through()
        pivot[keyPath: self.from].id = fromID
        pivot[keyPath: self.to].id = toID
        edit(pivot)
        return pivot.save(on: database)
    }

    public func detach(_ to: To, on database: Database) -> EventLoopFuture<Void> {
        guard let fromID = self.idValue else {
            fatalError("Cannot attach siblings relation to unsaved model.")
        }
        guard let toID = to.id else {
            fatalError("Cannot attach unsaved model.")
        }

        return Through.query(on: database)
            .filter(self.from.appending(path: \.$id) == fromID)
            .filter(self.to.appending(path: \.$id) == toID)
            .delete()
    }

    // MARK: Query

    public func query(on database: Database) -> QueryBuilder<To> {
        guard let fromID = self.idValue else {
            fatalError("Cannot query siblings relation from unsaved model.")
        }

        return To.query(on: database)
            .join(self.to)
            .filter(Through.self, self.from.appending(path: \.$id) == fromID)
    }

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

extension ModelSiblings: Relation {
    public var name: String {
        let fromKey = Through.key(for: self.from)
        let toKey = Through.key(for: self.to)
        return "Siblings<\(From.self), \(To.self), \(Through.self)>(from: \(fromKey), to: \(toKey))"
    }

    public func load(on database: Database) -> EventLoopFuture<Void> {
        self.query(on: database).all().map {
            self.value = $0
        }
    }
}

extension ModelSiblings: EagerLoadable {
    public static func eagerLoad<Builder>(
        _ relationKey: KeyPath<From, From.Siblings<To, Through>>,
        to builder: Builder
    )
        where Builder: EagerLoadBuilder, Builder.Model == From
    {
        let loader = SiblingsEagerLoader(relationKey: relationKey)
        builder.add(loader: loader)
    }


    public static func eagerLoad<Loader, Builder>(
        _ loader: Loader,
        through: KeyPath<From, From.Siblings<To, Through>>,
        to builder: Builder
    ) where
        Loader: EagerLoader,
        Loader.Model == To,
        Builder: EagerLoadBuilder,
        Builder.Model == From
    {
        let loader = ThroughSiblingsEagerLoader(relationKey: through, loader: loader)
        builder.add(loader: loader)
    }
}


private struct SiblingsEagerLoader<From, To, Through>: EagerLoader
    where From: Model, Through: Model, To: Model
{
    let relationKey: KeyPath<From, From.Siblings<To, Through>>

    func run(models: [From], on database: Database) -> EventLoopFuture<Void> {
        let ids = models.map { $0.id! }

        let from = From()[keyPath: self.relationKey].from
        let to = From()[keyPath: self.relationKey].to
        return To.query(on: database)
            .join(to)
            .filter(Through.self, from.appending(path: \.$id) ~~ Set(ids))
            .all()
            .flatMapThrowing
        {
            for model in models {
                let id = model[keyPath: self.relationKey].idValue!
                model[keyPath: self.relationKey].value = try $0.filter {
                    try $0.joined(Through.self)[keyPath: from].id == id
                }
            }
        }
    }
}

private struct ThroughSiblingsEagerLoader<From, To, Through, Loader>: EagerLoader
    where From: Model, Through: Model, Loader: EagerLoader, Loader.Model == To
{
    let relationKey: KeyPath<From, From.Siblings<To, Through>>
    let loader: Loader

    func run(models: [From], on database: Database) -> EventLoopFuture<Void> {
        let throughs = models.flatMap {
            $0[keyPath: self.relationKey].value!
        }
        return self.loader.run(models: throughs, on: database)
    }
}
