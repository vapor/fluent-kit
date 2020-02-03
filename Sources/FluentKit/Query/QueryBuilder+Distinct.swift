extension QueryBuilder {
    public func distinctCount<Field>(on key: KeyPath<Model, Field>) -> EventLoopFuture<Int>
        where Field: FieldRepresentable
    {
        let copy = self.copy()
        let fieldKey = Model.key(for: key)
        copy.query.fields = [.aggregate(.fields(method: .count, fields: [
                .function(.distinct, fields: [.field(path: [fieldKey], schema: Model.schema, alias: nil)])
            ]))
        ]
        return copy.first().flatMapThrowing { res in
            guard let res = res else {
                throw FluentError.noResults
            }
            return try res._$id.cachedOutput!.decode("fluentAggregate", as: Int.self)
        }
    }
    
    public func distinct<Result>(on key: KeyPath<Model, Field<Result>>) -> EventLoopFuture<[Result]> where Result: Decodable {
        let copy = self.copy()
        let fieldKey = Model.key(for: key)
        copy.query.isDistinct = true
        copy.query.fields = [.field(path: [fieldKey], schema: Model.schema, alias: nil)]
        return copy.all().flatMapThrowing { models in
            return try models.map { try $0._$id.cachedOutput!.decode(fieldKey, as: Result.self) }
        }
    }
    
    public func distinct() -> EventLoopFuture<[Model]> {
        self.query.isDistinct = true
        return self.all()
    }
}
