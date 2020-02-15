extension QueryBuilder {
    public func all<Result>(_ key: KeyPath<Model, Field<Result>>) -> EventLoopFuture<[Result]> where Result: Decodable {
        let copy = self.copy()
        let fieldKey = Model.key(for: key)
        copy.query.fields = [.field(path: [fieldKey], schema: Model.schema, alias: nil)]
        return copy.all().map { models in
            return models.map { $0[keyPath: key].wrappedValue }
        }
    }
    
    public func unique() -> Self {
        self.query.isUnique = true
        return self
    }
}
