public protocol EagerLoadable {
    associatedtype From: Model
    associatedtype To: Model

    static func eagerLoad<Builder>(
        _ relationKey: KeyPath<From, Self>,
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
