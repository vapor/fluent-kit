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
