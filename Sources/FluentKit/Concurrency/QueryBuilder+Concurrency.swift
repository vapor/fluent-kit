import NIOCore

public extension QueryBuilder {
    // MARK: - Actions
    func create() async throws {
        try await self.create().get()
    }
    
    func update() async throws {
        try await self.update().get()
    }
    
    func delete(force: Bool = false) async throws {
        try await self.delete(force: force).get()
    }
    
    // MARK: - Fetch
    
    func chunk(max: Int, closure: @escaping ([Result<Model, Error>]) -> ()) async throws {
        try await self.chunk(max: max, closure: closure).get()
    }
    
    func first() async throws -> Model? {
        try await self.first().get()
    }
    
    func all<Field>(_ key: KeyPath<Model, Field>) async throws -> [Field.Value]
        where Field: QueryableProperty, Field.Model == Model
    {
        try await self.all(key).get()
    }
    
    func all<Joined, Field>(
        _ joined: Joined.Type,
        _ field: KeyPath<Joined, Field>
    ) async throws -> [Field.Value]
        where Joined: Schema, Field: QueryableProperty, Field.Model == Joined
    {
        try await self.all(joined, field).get()
    }

    func all() async throws -> [Model] {
        try await self.all().get()
    }
    
    func run() async throws {
        try await self.run().get()
    }
    
    func all(_ onOutput: @escaping (Result<Model, Error>) -> ()) async throws {
        try await self.all(onOutput).get()
    }
    
    func run(_ onOutput: @escaping (DatabaseOutput) -> ()) async throws {
        try await self.run(onOutput).get()
    }
    
    // MARK: - Aggregate
    func count() async throws -> Int {
        try await self.count().get()
    }
    
    func count<Field>(_ key: KeyPath<Model, Field>) async throws  -> Int
        where Field: QueryableProperty, Field.Model == Model
    {
        try await self.count(key).get()
    }

    func count<Field>(_ key: KeyPath<Model, Field>) async throws  -> Int
        where Field: QueryableProperty, Field.Model == Model.IDValue
    {
        try await self.count(key).get()
    }

    func sum<Field>(_ key: KeyPath<Model, Field>) async throws -> Field.Value?
        where Field: QueryableProperty, Field.Model == Model
    {
        try await self.sum(key).get()
    }
    
    func sum<Field>(_ key: KeyPath<Model, Field>) async throws -> Field.Value?
        where Field: QueryableProperty, Field.Model == Model.IDValue
    {
        try await self.sum(key).get()
    }
    
    func sum<Field>(_ key: KeyPath<Model, Field>) async throws -> Field.Value
        where Field: QueryableProperty, Field.Value: OptionalType, Field.Model == Model
    {
        try await self.sum(key).get()
    }
    
    func sum<Field>(_ key: KeyPath<Model, Field>) async throws -> Field.Value
        where Field: QueryableProperty, Field.Value: OptionalType, Field.Model == Model.IDValue
    {
        try await self.sum(key).get()
    }
    
    func average<Field>(_ key: KeyPath<Model, Field>) async throws -> Field.Value?
        where Field: QueryableProperty, Field.Model == Model
    {
        try await self.average(key).get()
    }
    
    func average<Field>(_ key: KeyPath<Model, Field>) async throws -> Field.Value?
        where Field: QueryableProperty, Field.Model == Model.IDValue
    {
        try await self.average(key).get()
    }
    
    func average<Field>(_ key: KeyPath<Model, Field>) async throws -> Field.Value
        where Field: QueryableProperty, Field.Value: OptionalType, Field.Model == Model
    {
        try await self.average(key).get()
    }
    
    func average<Field>(_ key: KeyPath<Model, Field>) async throws -> Field.Value
        where Field: QueryableProperty, Field.Value: OptionalType, Field.Model == Model.IDValue
    {
        try await self.average(key).get()
    }
    
    func min<Field>(_ key: KeyPath<Model, Field>) async throws -> Field.Value?
        where Field: QueryableProperty, Field.Model == Model
    {
        try await self.min(key).get()
    }
    
    func min<Field>(_ key: KeyPath<Model, Field>) async throws -> Field.Value?
        where Field: QueryableProperty, Field.Model == Model.IDValue
    {
        try await self.min(key).get()
    }
    
    func min<Field>(_ key: KeyPath<Model, Field>) async throws -> Field.Value
        where Field: QueryableProperty, Field.Value: OptionalType, Field.Model == Model
    {
        try await self.min(key).get()
    }
    
    func min<Field>(_ key: KeyPath<Model, Field>) async throws -> Field.Value
        where Field: QueryableProperty, Field.Value: OptionalType, Field.Model == Model.IDValue
    {
        try await self.min(key).get()
    }
    
    func max<Field>(_ key: KeyPath<Model, Field>) async throws -> Field.Value?
        where Field: QueryableProperty, Field.Model == Model
    {
        try await self.max(key).get()
    }
    
    func max<Field>(_ key: KeyPath<Model, Field>) async throws -> Field.Value?
        where Field: QueryableProperty, Field.Model == Model.IDValue
    {
        try await self.max(key).get()
    }
    
    func max<Field>(_ key: KeyPath<Model, Field>) async throws -> Field.Value
        where Field: QueryableProperty, Field.Value: OptionalType, Field.Model == Model
    {
        try await self.max(key).get()
    }
    
    func max<Field>(_ key: KeyPath<Model, Field>) async throws -> Field.Value
        where Field: QueryableProperty, Field.Value: OptionalType, Field.Model == Model.IDValue
    {
        try await self.max(key).get()
    }

    func aggregate<Field, Result>(
        _ method: DatabaseQuery.Aggregate.Method,
        _ field: KeyPath<Model, Field>,
        as type: Result.Type = Result.self
    ) async throws -> Result
        where Field: QueryableProperty, Field.Model == Model, Result: Codable
    {
        try await self.aggregate(method, field, as: type).get()
    }
    
    func aggregate<Field, Result>(
        _ method: DatabaseQuery.Aggregate.Method,
        _ field: KeyPath<Model, Field>,
        as type: Result.Type = Result.self
    ) async throws -> Result
        where Field: QueryableProperty, Field.Model == Model.IDValue, Result: Codable
    {
        try await self.aggregate(method, field, as: type).get()
    }
    
    func aggregate<Result>(
        _ method: DatabaseQuery.Aggregate.Method,
        _ field: FieldKey,
        as type: Result.Type = Result.self
    ) async throws -> Result
        where Result: Codable
    {
        try await self.aggregate(method, field, as: type).get()
    }
    
    func aggregate<Result>(
        _ method: DatabaseQuery.Aggregate.Method,
        _ path: [FieldKey],
        as type: Result.Type = Result.self
    ) async throws -> Result
        where Result: Codable
    {
        try await self.aggregate(method, path, as: type).get()
    }
    
    // MARK: - Paginate
    func paginate(
        _ request: PageRequest
    ) async throws -> Page<Model> {
        try await self.paginate(request).get()
    }
    
    func page(
        withIndex page: Int,
        size per: Int
    ) async throws -> Page<Model> {
        try await self.page(withIndex: page, size: per).get()
    }
}
