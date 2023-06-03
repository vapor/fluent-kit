import NIOCore

extension Model {
    public typealias Siblings<To, Through> = SiblingsProperty<Self, To, Through>
        where To: Model, Through: Model
}

// MARK: Type

@propertyWrapper
public final class SiblingsProperty<From, To, Through>
    where From: Model, To: Model, Through: Model
{
    public enum AttachMethod {
        /// Always create the pivot model
        case always

        /// Only create the pivot if it doesn't already exist
        case ifNotExists
    }

    public let from: KeyPath<Through, Through.Parent<From>>
    public let to: KeyPath<Through, Through.Parent<To>>
    var idValue: From.IDValue?
    
    public var value: [To]?
    
    /// Allows eager loading of pivot objects through the sibling relation.
    /// Example:
    ///
    ///     Planet.query(on: db)
    ///         .with(\.$tags).with(\.$tags.$pivots).first() { planet in
    ///             // you can now access the loaded pivots using:
    ///             let pivots = planet.$tags.pivots
    ///         }
    @ChildrenProperty<From, Through>
    public var pivots: [Through]

    public init(
        through _: Through.Type,
        from: KeyPath<Through, Through.Parent<From>>,
        to: KeyPath<Through, Through.Parent<To>>
    ) {
        guard !(From.IDValue.self is Fields.Type), !(To.IDValue.self is Fields.Type) else {
            fatalError("Can not use @Siblings with models which have composite IDs.")
        }

        self.from = from
        self.to = to
        self._pivots = ChildrenProperty<From, Through>(for: from)
    }

    public var wrappedValue: [To] {
        get {
            guard let value = self.value else {
                fatalError("Siblings relation not eager loaded, use $ prefix to access: \(self.name)")
            }
            return value
        }
        set {
            fatalError("Siblings relation \(self.name) is get-only.")
        }
    }

    public var projectedValue: SiblingsProperty<From, To, Through> {
        return self
    }

    public var fromId: From.IDValue? {
        get { return self.idValue }
        set { self.idValue = newValue }
    }

    // MARK: Checking state

    /// Check whether a specific model is already attached through a sibling relationship.
    ///
    /// - Parameters:
    ///     - to: The model to check whether it is attached through a pivot.
    ///     - database: The database to perform check on.
    public func isAttached(to: To, on database: Database) -> EventLoopFuture<Bool> {
        guard let toID = to.id else {
            fatalError("Cannot attach unsaved model.")
        }

        return self.isAttached(toID: toID, on: database)
    }

    /// Check whether a specific model ID is already attached through a sibling relationship.
    ///
    /// - Parameters:
    ///     - toID: The ID of the model to check whether it is attached through a pivot.
    ///     - database: The database to perform the check on.
    public func isAttached(toID: To.IDValue, on database: Database) -> EventLoopFuture<Bool> {
        guard let fromID = self.idValue else {
            fatalError("Cannot check if siblings are attached to an unsaved model in \(self.name).")
        }

        return Through.query(on: database)
            .filter(self.from.appending(path: \.$id) == fromID)
            .filter(self.to.appending(path: \.$id) == toID)
            .first()
            .map { $0 != nil }
    }

    // MARK: Operations

    /// Attach an array model to this model through a pivot.
    ///
    /// - Parameters:
    ///     - tos: An array of models to attach through a sibling releationship
    ///     - database: The database to perform the attachment on.
    ///     - edit: An optional closure to edit the pivot model before saving it.
    public func attach(
        _ tos: [To],
        on database: Database,
        _ edit: (Through) -> () = { _ in }
    ) -> EventLoopFuture<Void> {
        guard let fromID = self.idValue else {
            fatalError("Cannot attach siblings relation \(self.name) to unsaved model.")
        }

        return tos.map { to -> Through in
            guard let toID = to.id else {
                fatalError("Cannot attach unsaved model to \(self.name).")
            }
            let pivot = Through()
            pivot[keyPath: self.from].id = fromID
            pivot[keyPath: self.to].id = toID
            pivot[keyPath: self.to].value = to
            edit(pivot)
            return pivot
        }.create(on: database)
    }

    /// Attach a single model by creating a pivot model and specifying the attachment method.
    ///
    /// - Parameters:
    ///     - to: The model to attach through a sibling releationship
    ///     - method: The attachment method to use when deciding whether to create the pivot.
    ///     - database: The database to perform the attachment on.
    ///     - edit: An optional closure to edit the pivot model before saving it.
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

    /// Attach a single model by creating a pivot model.
    ///
    /// - Parameters:
    ///     - to: The model to attach through a sibling releationship
    ///     - database: The database to perform the attachment on.
    ///     - edit: An optional closure to edit the pivot model before saving it.
    public func attach(
        _ to: To,
        on database: Database,
        _ edit: (Through) -> () = { _ in }
    ) -> EventLoopFuture<Void> {
        guard let fromID = self.idValue else {
            fatalError("Cannot attach siblings relation \(self.name) to unsaved model.")
        }
        guard let toID = to.id else {
            fatalError("Cannot attach unsaved model \(self.name).")
        }

        let pivot = Through()
        pivot[keyPath: self.from].id = fromID
        pivot[keyPath: self.to].id = toID
        pivot[keyPath: self.to].value = to
        edit(pivot)
        return pivot.save(on: database)
    }

    /// Detaches an array of models from this model by deleting each pivot.
    ///
    /// - Parameters:
    ///     - tos: An array of models to detach from this model.
    ///     - database: The database to perform the attachment on.
    public func detach(_ tos: [To], on database: Database) -> EventLoopFuture<Void> {
        guard let fromID = self.idValue else {
            fatalError("Cannot detach siblings relation \(self.name) to unsaved model.")
        }
        let toIDs = tos.map { to -> To.IDValue in
            guard let toID = to.id else {
                fatalError("Cannot detach unsaved model \(self.name).")
            }
            return toID
        }

        return Through.query(on: database)
            .filter(self.from.appending(path: \.$id) == fromID)
            .filter(self.to.appending(path: \.$id) ~~ toIDs)
            .delete()
    }

    /// Detach a single model by deleting the pivot.
    ///
    /// - Parameters:
    ///     - to: The model to detach from this model.
    ///     - database: The database to perform the attachment on.
    public func detach(_ to: To, on database: Database) -> EventLoopFuture<Void> {
        guard let fromID = self.idValue else {
            fatalError("Cannot detach siblings relation \(self.name) from unsaved model.")
        }
        guard let toID = to.id else {
            fatalError("Cannot detach unsaved model \(self.name).")
        }

        return Through.query(on: database)
            .filter(self.from.appending(path: \.$id) == fromID)
            .filter(self.to.appending(path: \.$id) == toID)
            .delete()
    }
    
    /// Detach all models by deleting all pivots from this model.
    public func detachAll(on database: Database) -> EventLoopFuture<Void> {
        guard let fromID = self.idValue else {
            fatalError("Cannot detach siblings relation \(self.name) from unsaved model.")
        }
        
        return Through.query(on: database)
            .filter(self.from.appending(path: \.$id) == fromID)
            .delete()
    }

    // MARK: Query

    /// Returns a `QueryBuilder` that can be used to query the siblings.
    public func query(on database: Database) -> QueryBuilder<To> {
        guard let fromID = self.idValue else {
            fatalError("Cannot query siblings relation \(self.name) from unsaved model.")
        }

        return To.query(on: database)
            .join(Through.self, on: \To._$id == self.to.appending(path: \.$id))
            .filter(Through.self, self.from.appending(path: \.$id) == fromID)
    }
}

extension SiblingsProperty: CustomStringConvertible {
    public var description: String {
        self.name
    }
}

// MARK: Property

extension SiblingsProperty: AnyProperty { }

extension SiblingsProperty: Property {
    public typealias Model = From
    public typealias Value = [To]
}

// MARK: Database

extension SiblingsProperty: AnyDatabaseProperty {
    public var keys: [FieldKey] {
        []
    }
    
    public func input(to input: DatabaseInput) {
        // siblings never has input
    }

    public func output(from output: DatabaseOutput) throws {
        let key = From()._$id.key
        if output.contains(key) {
            self.idValue = try output.decode(key, as: From.IDValue.self)
            self._pivots.idValue = self.idValue
        }
    }
}

// MARK: Codable

extension SiblingsProperty: AnyCodableProperty {
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

extension SiblingsProperty: Relation {
    public var name: String {
        let fromKey = Through.path(for: self.from.appending(path: \.$id))
        let toKey = Through.path(for: self.to.appending(path: \.$id))
        return "Siblings<\(From.self), \(To.self), \(Through.self)>(from: \(fromKey), to: \(toKey))"
    }

    public func load(on database: Database) -> EventLoopFuture<Void> {
        self.query(on: database).all().map {
            self.value = $0
        }
    }
}

// MARK: Eager Loadable

extension SiblingsProperty: EagerLoadable {
    public static func eagerLoad<Builder>(
        _ relationKey: KeyPath<From, SiblingsProperty<From, To, Through>>,
        to builder: Builder
    )
    where Builder : EagerLoadBuilder, From == Builder.Model
    {
        self.eagerLoad(relationKey, withDeleted: false, to: builder)
    }
    
    public static func eagerLoad<Builder>(
        _ relationKey: KeyPath<From, From.Siblings<To, Through>>,
        withDeleted: Bool,
        to builder: Builder
    )
        where Builder: EagerLoadBuilder, Builder.Model == From
    {
        let loader = SiblingsEagerLoader(relationKey: relationKey, withDeleted: withDeleted)
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
    let withDeleted: Bool

    func run(models: [From], on database: Database) -> EventLoopFuture<Void> {
        let ids = models.map { $0.id! }

        let from = From()[keyPath: self.relationKey].from
        let to = From()[keyPath: self.relationKey].to
        let builder = To.query(on: database)
            .join(Through.self, on: \To._$id == to.appending(path: \.$id))
            .filter(Through.self, from.appending(path: \.$id) ~~ Set(ids))
        if (self.withDeleted) {
            builder.withDeleted()
        }
        return builder.all()
            .flatMapThrowing
        {
            var map: [From.IDValue: [To]] = [:]
            for to in $0 {
                let fromID = try to.joined(Through.self)[keyPath: from].id
                map[fromID, default: []].append(to)
            }
            for model in models {
                guard let id = model.id else { throw FluentError.idRequired }
                model[keyPath: self.relationKey].value = map[id] ?? []
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
