extension Model {
    public typealias CompositeChildren<To> = CompositeChildrenProperty<Self, To>
        where To: FluentKit.Model, Self.IDValue: Fields
}

@propertyWrapper
public final class CompositeChildrenProperty<From, To>
    where From: Model, To: Model, From.IDValue: Fields
{
    public let parentKey: KeyPath<To, To.CompositeParent<From>>
    var idValue: From.IDValue?

    public var value: [To]?

    public init(for parentKey: KeyPath<To, To.CompositeParent<From>>) {
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

    public var projectedValue: CompositeChildrenProperty<From, To> { self }
    
    public var fromId: From.IDValue? {
        get { return self.idValue }
        set { self.idValue = newValue }
    }

    public func query(on database: Database) -> QueryBuilder<To> {
        guard let id = self.idValue else {
            fatalError("Cannot query children relation \(self.name) from unsaved model.")
        }

        /// Route the value through an instance of the child model's parent property. This ensures the
        /// correct prefix and strategy for this specific relation are applied to the filter keys.
        let parentProp = To()[keyPath: self.parentKey]
        parentProp.id = id

        /// Apply filters for each property of the ID to a query builder for the child model. See
        /// the documentation for ``QueryFilterInput`` for details of how this works.
        return To.query(on: database).group(.and) { parentProp.input(to: QueryFilterInput(builder: $0)) }
    }
}

extension CompositeChildrenProperty: CustomStringConvertible {
    public var description: String { self.name }
}

extension CompositeChildrenProperty: AnyProperty { }

extension CompositeChildrenProperty: Property {
    public typealias Model = From
    public typealias Value = [To]
}

extension CompositeChildrenProperty: AnyDatabaseProperty {
    public var keys: [FieldKey] { [] }
    public func input(to input: DatabaseInput) {}
    public func output(from output: DatabaseOutput) throws {
        if From.IDValue.keys.reduce(true, { $0 && output.contains($1) }) { // don't output unless all keys are present
            self.idValue = From.IDValue()
            try self.idValue!.output(from: output)
        }
    }
}

extension CompositeChildrenProperty: AnyCodableProperty {
    public func encode(to encoder: Encoder) throws {
        if let value = self.value {
            var container = encoder.singleValueContainer()
            try container.encode(value)
        }
    }
    public func decode(from decoder: Decoder) throws {}
    public var skipPropertyEncoding: Bool { self.value == nil }
}

extension CompositeChildrenProperty: Relation {
    public var name: String { "CompositeChildren<\(From.self), \(To.self)>(for: \(self.parentKey))" }
    public func load(on database: Database) -> EventLoopFuture<Void> { self.query(on: database).all().map { self.value = $0 } }
}

extension CompositeChildrenProperty: EagerLoadable {
    public static func eagerLoad<Builder>(_ relationKey: KeyPath<From, From.CompositeChildren<To>>, to builder: Builder)
        where Builder: EagerLoadBuilder, Builder.Model == From
    {
        let loader = CompositeChildrenEagerLoader(relationKey: relationKey)
        builder.add(loader: loader)
    }


    public static func eagerLoad<Loader, Builder>(_ loader: Loader, through: KeyPath<From, From.CompositeChildren<To>>, to builder: Builder)
        where Loader: EagerLoader, Loader.Model == To, Builder: EagerLoadBuilder, Builder.Model == From
    {
        let loader = ThroughCompositeChildrenEagerLoader(relationKey: through, loader: loader)
        builder.add(loader: loader)
    }
}

private struct CompositeChildrenEagerLoader<From, To>: EagerLoader
    where From: Model, To: Model, From.IDValue: Fields
{
    let relationKey: KeyPath<From, From.CompositeChildren<To>>

    func run(models: [From], on database: Database) -> EventLoopFuture<Void> {
        let ids = Set(models.map(\.id!))
        let parentKey = From()[keyPath: self.relationKey].parentKey
        let parentProp = To()[keyPath: parentKey]
        let builder = To.query(on: database)
        
        builder.group(.or) { query in
            _ = ids.reduce(query) { query, id in
                query.group(.and) {
                    parentProp.id = id
                    parentProp.input(to: QueryFilterInput(builder: $0))
                }
            }
        }
        
        return builder.all().map {
            let indexedResults = Dictionary(grouping: $0, by: { $0[keyPath: parentKey].id })
            
            for model in models {
                model[keyPath: self.relationKey].value = indexedResults[model[keyPath: self.relationKey].idValue!]
            }
        }
    }
}

private struct ThroughCompositeChildrenEagerLoader<From, Through, Loader>: EagerLoader
    where From: Model, From.IDValue: Fields, Loader: EagerLoader, Loader.Model == Through
{
    let relationKey: KeyPath<From, From.CompositeChildren<Through>>
    let loader: Loader

    func run(models: [From], on database: Database) -> EventLoopFuture<Void> {
        let throughs = models.flatMap {
            $0[keyPath: self.relationKey].value!
        }
        return self.loader.run(models: throughs, on: database)
    }
}
