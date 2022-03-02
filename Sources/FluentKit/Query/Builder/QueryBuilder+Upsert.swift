public class UpsertBuilder<Model> where Model: FluentKit.Model {

    public var values = [FieldKey: DatabaseQuery.Value]()

    @discardableResult
    public func set<Field>(
        _ field: KeyPath<Model, Field>,
        to value: Field.Value
    ) -> Self
        where
            Field: QueryableProperty,
            Field.Model == Model
    {
        let path = Model.path(for: field)
        assert(path.count == 1, "Set on nested properties is not yet supported.")
        values[path[0]] = Field.queryValue(value)

        return self
    }
}


extension QueryBuilder {

    public enum ConflictStrategy {
        case ignore
        case update((UpsertBuilder<Model>) -> Void)
    }

    public func create<Field>(
        onConflict field: KeyPath<Model, Field>,
        strategy: ConflictStrategy
    ) -> EventLoopFuture<Void>
        where
            Field: QueryableProperty,
            Field.Model == Model
    {
        create(onConflict: Model.path(for: field), strategy: strategy)
    }

    public func create(onConflict fields: [FieldKey], strategy: ConflictStrategy) -> EventLoopFuture<Void> {
        query.conflictResolutionStrategy = .init(fields: fields, strategy: strategy)
        query.action = .create
        return self.run()
    }
}
