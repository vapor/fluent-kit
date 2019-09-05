private protocol SubqueryLoader: EagerLoadRequest {
    associatedtype FromParent: ModelIdentifiable
    associatedtype FromModel: Model
    associatedtype ToModel: Model

    var loader: Children<FromParent, ToModel>.SubqueryEagerLoad { get }
}

extension SubqueryLoader {
    var description: String { self.loader.storage.description }

    func prepare(query: inout DatabaseQuery) { /* Do nothing */ }

    func run(models: [AnyModel], on database: Database) -> EventLoopFuture<Void> {
        let ids: [FromParent.IDValue] = models
            .map { $0 as! FromParent }
            .map { $0.id! }

        return ToModel.query(on: database)
            .filter(self.loader.parentKey.appending(path: \.$id), in: Set(ids))
            .all()
            .map { (children: [ToModel]) -> Void in
                self.loader.storage = children
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
            return self.request.run(models: models, on: database)
        }

        func get(id: From.IDValue) throws -> [To] {
            return self.storage.filter { child in child[keyPath: self.parentKey].id == id }
        }
    }
}

extension Children.SubqueryEagerLoad where From: Model {
    internal convenience init(_ parentKey: KeyPath<To, Parent<From>>) {
        self.init(parentKey, request: Required.init(loader:))
    }

    private final class Required: SubqueryLoader {
        typealias FromParent = From
        typealias FromModel = From
        typealias ToModel = To

        let loader: Children.SubqueryEagerLoad

        init(loader: Children.SubqueryEagerLoad) {
            self.loader = loader
        }
    }
}

extension Children.SubqueryEagerLoad where From: OptionalType, From.Wrapped: Model {
    internal convenience init(_ parentKey: KeyPath<To, Parent<From>>) {
        self.init(parentKey, request: Optional.init(loader:))
    }

    private final class Optional: SubqueryLoader {
        typealias FromParent = From
        typealias FromModel = From.Wrapped
        typealias ToModel = To

        let loader: Children.SubqueryEagerLoad

        init(loader: Children.SubqueryEagerLoad) {
            self.loader = loader
        }
    }
}
