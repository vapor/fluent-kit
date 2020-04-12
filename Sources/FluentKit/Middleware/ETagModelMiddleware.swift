
/// Middleware for `Model` objects which implement `EntityTaggableModel`
///
/// Provides default implementations for `update(model:)` and `create(model:)` which
/// set the eTag for you based on the model's `generateETag()` method.
public protocol ETagModelMiddleware: ModelMiddleware {}

public extension ETagModelMiddleware where Model: EntityTaggableModel {
    func update(model: Model, on db: Database, next: AnyModelResponder) -> EventLoopFuture<Void> {
        model.eTag = model.generateETag()
        return next.update(model, on: db)
    }

    func create(model: Model, on db: Database, next: AnyModelResponder) -> EventLoopFuture<Void> {
        if model._$eTag.value == nil {
            model.eTag = model.generateETag()
        }

        return next.create(model, on: db)
    }
}
