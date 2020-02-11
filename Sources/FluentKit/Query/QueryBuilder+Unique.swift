extension QueryBuilder {
    public func unique<Result>(on key: KeyPath<Model, Field<Result>>) -> EventLoopFuture<[Result]> where Result: Decodable {
        let copy = self.copy()
        let fieldKey = Model.key(for: key)
        copy.query.isUnique = true
        copy.query.fields = [.field(path: [fieldKey], schema: Model.schema, alias: nil)]
        return copy.all().flatMapThrowing { models in
            return try models.map { try $0._$id.cachedOutput!.decode(fieldKey, as: Result.self) }
        }
    }
    
    public func unique() -> Self {
        self.query.isUnique = true
        return self
    }
}
