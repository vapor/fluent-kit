extension DatabaseQuery {

    public struct ConflictResolutionStrategy {
        public var targets: [Field]
        public var action: ConflictAction

        public enum ConflictAction {
            case ignore
            case update([FieldKey: Value])
        }

        init<Model: FluentKit.Model>(fields: [FieldKey], strategy: QueryBuilder<Model>.ConflictStrategy) {
            targets = fields.map { DatabaseQuery.Field.path([$0], schema: Model.schema) }

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
        }
    }
}

extension DatabaseQuery.ConflictResolutionStrategy: CustomStringConvertible {
    public var description: String {
        "on \(targets) \(action)"
    }
}

extension DatabaseQuery.ConflictResolutionStrategy.ConflictAction: CustomStringConvertible {
    public var description: String {
        switch self {
        case .ignore:
            return "ignore"
        case .update(let values):
            return "update \(values)"
        }
    }
}
