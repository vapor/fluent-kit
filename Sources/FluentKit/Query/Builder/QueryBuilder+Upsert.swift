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

    public enum ConflictStrategy<Model: FluentKit.Model> {
        case ignore
        case update((UpsertBuilder<Model>) -> Void)
    }

    public func create<Field>(
        onConflict field: KeyPath<Model, Field>,
        strategy: ConflictStrategy<Model>
    ) -> EventLoopFuture<Void>
        where
            Field: QueryableProperty,
            Field.Model == Model
    {
        create(onConflict: Model.path(for: field), strategy: strategy)
    }

    public func create(onConflict fields: [FieldKey], strategy: ConflictStrategy<Model>) -> EventLoopFuture<Void> {
        let targets = fields.map { DatabaseQuery.Field.path([$0], schema: Model.schema) }

        let action: DatabaseQuery.ConflictResolutionStrategy.ConflictAction
        switch strategy {
        case .ignore:
            action = .ignore
        case .update(let closure):
            let builder = UpsertBuilder<Model>()
            closure(builder)
            var updates = builder.values

            let timestamps = Model().timestamps.filter { $0.trigger == .update }
            for timestamp in timestamps {
                // Only add timestamps if they weren't already set
                if updates[timestamp.key] == nil {
                    updates[timestamp.key] = timestamp.currentTimestampInput
                }
            }

            action = .update(updates)
        }
        query.conflictResolutionStrategy = .init(targets: targets, action: action)

        query.action = .create
        return self.run()
    }
}
