private protocol SubqueryLoader: EagerLoadRequest {
    associatedtype FromModel: Model
    associatedtype ToParent: ModelIdentifiable
    associatedtype ToModel: Model

    var loader: Children<FromModel, ToParent>.SubqueryEagerLoad { get }

    func map(model: ToModel) -> ToParent
}

extension SubqueryLoader {
    func prepare(query: inout DatabaseQuery) { /* Do nothing */ }

    func run(models: [AnyModel], on database: Database) -> EventLoopFuture<Void> {
        let ids: [FromModel.IDValue] = models
            .map { $0 as! FromModel }
            .map { $0.id! }

        return ToModel.query(on: database)
            .filter(self.loader.parentKey.appending(path: \.$id), in: Set(ids))
            .all()
            .map { (children: [ToModel]) -> Void in
                self.loader.storage = children.map(self.map(model:))
            }
    }
}

extension Children {
    final class SubqueryEagerLoad: EagerLoadRequest {
        var storage: [To]
        let parentKey: KeyPath<To, Parent<From>>
        private var request: EagerLoadRequest!

        var description: String { self.storage.description }

        private init<Request>(_ parentKey: KeyPath<To, Parent<From>>, request generator: (Children.SubqueryEagerLoad) -> Request)
            where Request: SubqueryLoader
        {
            self.storage = []
            self.parentKey = parentKey
            self.request = nil

            self.request = generator(self)
        }

        func prepare(query: inout DatabaseQuery) {
            self.request.prepare(query: &query)
        }

        func run(models: [AnyModel], on database: Database) -> EventLoopFuture<Void> {
            return self.run(models: models, on: database)
        }

        func get(id: From.IDValue) throws -> [To] {
            return self.storage.filter { child in child[keyPath: self.parentKey].id == id }
        }
    }
}

extension Children.SubqueryEagerLoad where Children.To: Model {
    internal convenience init(_ parentKey: KeyPath<T, Parent<F>>) {
        self.init(parentKey, request: Required.init(loader:))
    }

    private final class Required: SubqueryLoader {
        typealias ToModel = T

        let loader: Children.SubqueryEagerLoad

        init(loader: Children.SubqueryEagerLoad) {
            self.loader = loader
        }

        func map(model: T) -> T { model }
    }
}

extension Children.SubqueryEagerLoad where Children.To: OptionalType, Children.To.Wrapped: Model {
    internal convenience init(_ parentKey: KeyPath<T, Parent<F>>) {
        self.init(parentKey, request: Optional.init(loader:))
    }

    private final class Optional: SubqueryLoader {
        typealias ToModel = T.Wrapped

        let loader: Children.SubqueryEagerLoad

        init(loader: Children.SubqueryEagerLoad) {
            self.loader = loader
        }

        func map(model: T.Wrapped) -> T { model as! T }
    }
}
