extension QueryBuilder {    
    public func distinct<Result>(on key: KeyPath<Model, Field<Result>>) -> EventLoopFuture<[Result]> where Result: Decodable {
        let copy = self.copy()
        let fieldKey = Model.key(for: key)
        copy.query.isDistinct = true
        copy.query.fields = [.field(path: [fieldKey], schema: Model.schema, alias: nil)]
        return copy.all().flatMapThrowing { models in
            return try models.compactMap { try $0._$id.cachedOutput!.decode(fieldKey, as: Result.self) }
        }
    }
    
    public func distinct() -> EventLoopFuture<[Model]> {
        self.query.isDistinct = true
        return self.all()
    }
}
