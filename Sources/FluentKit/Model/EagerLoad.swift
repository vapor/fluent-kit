import NIOCore

public protocol EagerLoader: AnyEagerLoader {
    associatedtype Model: FluentKit.Model
    func run(models: [Model], on database: Database) -> EventLoopFuture<Void>
}

extension EagerLoader {
    func anyRun(models: [AnyModel], on database: Database) -> EventLoopFuture<Void> {
        self.run(models: models.map { $0 as! Model }, on: database)
    }
}

public protocol AnyEagerLoader {
    func anyRun(models: [AnyModel], on database: Database) -> EventLoopFuture<Void>
}

public protocol EagerLoadable {
    associatedtype From: Model
    associatedtype To: Model

    static func eagerLoad<Builder>(
        _ relationKey: KeyPath<From, Self>,
        to builder: Builder
    ) where Builder: EagerLoadBuilder, Builder.Model == From
    
    static func eagerLoad<Builder>(
        _ relationKey: KeyPath<From, Self>,
        withDeleted: Bool,
        to builder: Builder
    ) where Builder: EagerLoadBuilder, Builder.Model == From

    static func eagerLoad<Loader, Builder>(
        _ loader: Loader,
        through: KeyPath<From, Self>,
        to builder: Builder
    ) where Loader: EagerLoader,
        Builder: EagerLoadBuilder,
        Loader.Model == To,
        Builder.Model == From
}

extension EagerLoadable {
    public static func eagerLoad<Builder>(
        _ relationKey: KeyPath<From, Self>,
        withDeleted: Bool,
        to builder: Builder
    ) where Builder: EagerLoadBuilder, Builder.Model == From {
        return Self.eagerLoad(relationKey, to: builder)
    }
}
