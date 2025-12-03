import NIOCore

extension QueryBuilder {
    // MARK: - Actions
    public func create() async throws {
        try await self.create().get()
    }

    public func update() async throws {
        try await self.update().get()
    }

    public func delete(force: Bool = false) async throws {
        try await self.delete(force: force).get()
    }

    // MARK: - Fetch

    public func chunk(max: Int, closure: @escaping @Sendable ([Result<Model, any Error>]) -> Void) async throws {
        try await self.chunk(max: max, closure: closure).get()
    }

    public func first() async throws -> Model? {
        try await self.first().get()
    }

    public func all<Field>(_ key: KeyPath<Model, Field>) async throws -> [Field.Value]
    where Field: QueryableProperty, Field.Model == Model {
        try await self.all(key).get()
    }

    public func all<Joined, Field>(
        _ joined: Joined.Type,
        _ field: KeyPath<Joined, Field>
    ) async throws -> [Field.Value]
    where Joined: Schema, Field: QueryableProperty, Field.Model == Joined {
        try await self.all(joined, field).get()
    }

    public func all() async throws -> [Model] {
        try await self.all().get()
    }

    public func run() async throws {
        try await self.run().get()
    }

    public func all(_ onOutput: @escaping @Sendable (Result<Model, any Error>) -> Void) async throws {
        try await self.all(onOutput).get()
    }

    public func run(_ onOutput: @escaping @Sendable (any DatabaseOutput) -> Void) async throws {
        try await self.run(onOutput).get()
    }

    // MARK: - Aggregate
    public func count() async throws -> Int {
        try await self.count().get()
    }

    public func count<Field>(_ key: KeyPath<Model, Field>) async throws -> Int
    where Field: QueryableProperty, Field.Model == Model, Field.Value: Sendable {
        try await self.count(key).get()
    }

    public func count<Field>(_ key: KeyPath<Model, Field>) async throws -> Int
    where Field: QueryableProperty, Field.Model == Model.IDValue, Field.Value: Sendable {
        try await self.count(key).get()
    }

    public func sum<Field>(_ key: KeyPath<Model, Field>) async throws -> Field.Value?
    where Field: QueryableProperty, Field.Model == Model, Field.Value: Sendable {
        try await self.sum(key).get()
    }

    public func sum<Field>(_ key: KeyPath<Model, Field>) async throws -> Field.Value?
    where Field: QueryableProperty, Field.Model == Model.IDValue, Field.Value: Sendable {
        try await self.sum(key).get()
    }

    public func sum<Field>(_ key: KeyPath<Model, Field>) async throws -> Field.Value
    where Field: QueryableProperty, Field.Value: OptionalType & Sendable, Field.Model == Model {
        try await self.sum(key).get()
    }

    public func sum<Field>(_ key: KeyPath<Model, Field>) async throws -> Field.Value
    where Field: QueryableProperty, Field.Value: OptionalType & Sendable, Field.Model == Model.IDValue {
        try await self.sum(key).get()
    }

    public func average<Field>(_ key: KeyPath<Model, Field>) async throws -> Field.Value?
    where Field: QueryableProperty, Field.Model == Model, Field.Value: Sendable {
        try await self.average(key).get()
    }

    public func average<Field>(_ key: KeyPath<Model, Field>) async throws -> Field.Value?
    where Field: QueryableProperty, Field.Model == Model.IDValue, Field.Value: Sendable {
        try await self.average(key).get()
    }

    public func average<Field>(_ key: KeyPath<Model, Field>) async throws -> Field.Value
    where Field: QueryableProperty, Field.Value: OptionalType & Sendable, Field.Model == Model {
        try await self.average(key).get()
    }

    public func average<Field>(_ key: KeyPath<Model, Field>) async throws -> Field.Value
    where Field: QueryableProperty, Field.Value: OptionalType & Sendable, Field.Model == Model.IDValue {
        try await self.average(key).get()
    }

    public func min<Field>(_ key: KeyPath<Model, Field>) async throws -> Field.Value?
    where Field: QueryableProperty, Field.Model == Model, Field.Value: Sendable {
        try await self.min(key).get()
    }

    public func min<Field>(_ key: KeyPath<Model, Field>) async throws -> Field.Value?
    where Field: QueryableProperty, Field.Model == Model.IDValue, Field.Value: Sendable {
        try await self.min(key).get()
    }

    public func min<Field>(_ key: KeyPath<Model, Field>) async throws -> Field.Value
    where Field: QueryableProperty, Field.Value: OptionalType & Sendable, Field.Model == Model {
        try await self.min(key).get()
    }

    public func min<Field>(_ key: KeyPath<Model, Field>) async throws -> Field.Value
    where Field: QueryableProperty, Field.Value: OptionalType & Sendable, Field.Model == Model.IDValue {
        try await self.min(key).get()
    }

    public func max<Field>(_ key: KeyPath<Model, Field>) async throws -> Field.Value?
    where Field: QueryableProperty, Field.Model == Model, Field.Value: Sendable {
        try await self.max(key).get()
    }

    public func max<Field>(_ key: KeyPath<Model, Field>) async throws -> Field.Value?
    where Field: QueryableProperty, Field.Model == Model.IDValue, Field.Value: Sendable {
        try await self.max(key).get()
    }

    public func max<Field>(_ key: KeyPath<Model, Field>) async throws -> Field.Value
    where Field: QueryableProperty, Field.Value: OptionalType & Sendable, Field.Model == Model {
        try await self.max(key).get()
    }

    public func max<Field>(_ key: KeyPath<Model, Field>) async throws -> Field.Value
    where Field: QueryableProperty, Field.Value: OptionalType & Sendable, Field.Model == Model.IDValue {
        try await self.max(key).get()
    }

    public func aggregate<Field, Result>(
        _ method: DatabaseQuery.Aggregate.Method,
        _ field: KeyPath<Model, Field>,
        as type: Result.Type = Result.self
    ) async throws -> Result
    where Field: QueryableProperty, Field.Model == Model, Result: Codable & Sendable {
        try await self.aggregate(method, field, as: type).get()
    }

    public func aggregate<Field, Result>(
        _ method: DatabaseQuery.Aggregate.Method,
        _ field: KeyPath<Model, Field>,
        as type: Result.Type = Result.self
    ) async throws -> Result
    where Field: QueryableProperty, Field.Model == Model.IDValue, Result: Codable & Sendable {
        try await self.aggregate(method, field, as: type).get()
    }

    public func aggregate<Result>(
        _ method: DatabaseQuery.Aggregate.Method,
        _ field: FieldKey,
        as type: Result.Type = Result.self
    ) async throws -> Result
    where Result: Codable & Sendable {
        try await self.aggregate(method, field, as: type).get()
    }

    public func aggregate<Result>(
        _ method: DatabaseQuery.Aggregate.Method,
        _ path: [FieldKey],
        as type: Result.Type = Result.self
    ) async throws -> Result
    where Result: Codable & Sendable {
        try await self.aggregate(method, path, as: type).get()
    }

    // MARK: - Paginate
    public func paginate(
        _ request: PageRequest
    ) async throws -> Page<Model> {
        try await self.paginate(request).get()
    }

    public func page(
        withIndex page: Int,
        size per: Int
    ) async throws -> Page<Model> {
        try await self.page(withIndex: page, size: per).get()
    }
}
