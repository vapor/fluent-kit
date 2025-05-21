import NIOCore
import SQLKit

public extension QueryBuilder {
    // MARK: - Actions
    func create(annotationContext: SQLAnnotationContext? = nil) async throws {
        try await self.create(annotationContext: annotationContext).get()
    }
    
    func update(annotationContext: SQLAnnotationContext? = nil) async throws {
        try await self.update(annotationContext: annotationContext).get()
    }
    
    func delete(force: Bool = false, annotationContext: SQLAnnotationContext? = nil) async throws {
        try await self.delete(force: force, annotationContext: annotationContext).get()
    }
    
    // MARK: - Fetch
    
    func chunk(max: Int, annotationContext: SQLAnnotationContext?, closure: @escaping @Sendable ([Result<Model, any Error>]) -> ()) async throws {
        try await self.chunk(max: max, annotationContext: annotationContext, closure: closure).get()
    }
    
    func first(annotationContext: SQLAnnotationContext? = nil) async throws -> Model? {
        try await self.first(annotationContext: annotationContext).get()
    }
    
    func all<Field>(_ key: KeyPath<Model, Field>, annotationContext: SQLAnnotationContext?) async throws -> [Field.Value]
        where Field: QueryableProperty, Field.Model == Model
    {
        try await self.all(key, annotationContext: annotationContext).get()
    }
    
    func all<Joined, Field>(
        _ joined: Joined.Type,
        _ field: KeyPath<Joined, Field>,
        annotationContext: SQLAnnotationContext?
    ) async throws -> [Field.Value]
        where Joined: Schema, Field: QueryableProperty, Field.Model == Joined
    {
        try await self.all(joined, field, annotationContext: annotationContext).get()
    }

    func all(annotationContext: SQLAnnotationContext? = nil) async throws -> [Model] {
        try await self.all(annotationContext: annotationContext).get()
    }
    
    func run(annotationContext: SQLAnnotationContext?) async throws {
        try await self.run(annotationContext: annotationContext).get()
    }
    
    func all(annotationContext: SQLAnnotationContext?, _ onOutput: @escaping @Sendable (Result<Model, any Error>) -> ()) async throws {
        try await self.all(annotationContext: annotationContext, onOutput).get()
    }
    
    func run(annotationContext: SQLAnnotationContext?, _ onOutput: @escaping @Sendable (any DatabaseOutput) -> ()) async throws {
        try await self.run(annotationContext: annotationContext, onOutput).get()
    }
    
    // MARK: - Aggregate
    func count(annotationContext: SQLAnnotationContext? = nil) async throws -> Int {
        try await self.count(annotationContext: annotationContext).get()
    }
    
    func count<Field>(_ key: KeyPath<Model, Field>, annotationContext: SQLAnnotationContext? = nil) async throws  -> Int
        where Field: QueryableProperty, Field.Model == Model, Field.Value: Sendable
    {
        try await self.count(key, annotationContext: annotationContext).get()
    }

    func count<Field>(_ key: KeyPath<Model, Field>, annotationContext: SQLAnnotationContext? = nil) async throws  -> Int
        where Field: QueryableProperty, Field.Model == Model.IDValue, Field.Value: Sendable
    {
        try await self.count(key, annotationContext: annotationContext).get()
    }

    func sum<Field>(_ key: KeyPath<Model, Field>, annotationContext: SQLAnnotationContext? = nil) async throws -> Field.Value?
        where Field: QueryableProperty, Field.Model == Model, Field.Value: Sendable
    {
        try await self.sum(key, annotationContext: annotationContext).get()
    }
    
    func sum<Field>(_ key: KeyPath<Model, Field>, annotationContext: SQLAnnotationContext?) async throws -> Field.Value?
        where Field: QueryableProperty, Field.Model == Model.IDValue, Field.Value: Sendable
    {
        try await self.sum(key, annotationContext: annotationContext).get()
    }
    
    func sum<Field>(_ key: KeyPath<Model, Field>, annotationContext: SQLAnnotationContext? = nil) async throws -> Field.Value
        where Field: QueryableProperty, Field.Value: OptionalType & Sendable, Field.Model == Model
    {
        try await self.sum(key, annotationContext: annotationContext).get()
    }
    
    func sum<Field>(_ key: KeyPath<Model, Field>, annotationContext: SQLAnnotationContext? = nil) async throws -> Field.Value
        where Field: QueryableProperty, Field.Value: OptionalType & Sendable, Field.Model == Model.IDValue
    {
        try await self.sum(key, annotationContext: annotationContext).get()
    }
    
    func average<Field>(_ key: KeyPath<Model, Field>, annotationContext: SQLAnnotationContext? = nil) async throws -> Field.Value?
        where Field: QueryableProperty, Field.Model == Model, Field.Value: Sendable
    {
        try await self.average(key, annotationContext: annotationContext).get()
    }
    
    func average<Field>(_ key: KeyPath<Model, Field>, annotationContext: SQLAnnotationContext? = nil) async throws -> Field.Value?
        where Field: QueryableProperty, Field.Model == Model.IDValue, Field.Value: Sendable
    {
        try await self.average(key, annotationContext: annotationContext).get()
    }
    
    func average<Field>(_ key: KeyPath<Model, Field>, annotationContext: SQLAnnotationContext? = nil) async throws -> Field.Value
        where Field: QueryableProperty, Field.Value: OptionalType & Sendable, Field.Model == Model
    {
        try await self.average(key, annotationContext: annotationContext).get()
    }
    
    func average<Field>(_ key: KeyPath<Model, Field>, annotationContext: SQLAnnotationContext? = nil) async throws -> Field.Value
        where Field: QueryableProperty, Field.Value: OptionalType & Sendable, Field.Model == Model.IDValue
    {
        try await self.average(key, annotationContext: annotationContext).get()
    }
    
    func min<Field>(_ key: KeyPath<Model, Field>, annotationContext: SQLAnnotationContext? = nil) async throws -> Field.Value?
        where Field: QueryableProperty, Field.Model == Model, Field.Value: Sendable
    {
        try await self.min(key, annotationContext: annotationContext).get()
    }
    
    func min<Field>(_ key: KeyPath<Model, Field>, annotationContext: SQLAnnotationContext? = nil) async throws -> Field.Value?
        where Field: QueryableProperty, Field.Model == Model.IDValue, Field.Value: Sendable
    {
        try await self.min(key, annotationContext: annotationContext).get()
    }
    
    func min<Field>(_ key: KeyPath<Model, Field>, annotationContext: SQLAnnotationContext? = nil) async throws -> Field.Value
        where Field: QueryableProperty, Field.Value: OptionalType & Sendable, Field.Model == Model
    {
        try await self.min(key, annotationContext: annotationContext).get()
    }
    
    func min<Field>(_ key: KeyPath<Model, Field>, annotationContext: SQLAnnotationContext? = nil) async throws -> Field.Value
        where Field: QueryableProperty, Field.Value: OptionalType & Sendable, Field.Model == Model.IDValue
    {
        try await self.min(key, annotationContext: annotationContext).get()
    }
    
    func max<Field>(_ key: KeyPath<Model, Field>, annotationContext: SQLAnnotationContext? = nil) async throws -> Field.Value?
        where Field: QueryableProperty, Field.Model == Model, Field.Value: Sendable
    {
        try await self.max(key, annotationContext: annotationContext).get()
    }
    
    func max<Field>(_ key: KeyPath<Model, Field>, annotationContext: SQLAnnotationContext? = nil) async throws -> Field.Value?
        where Field: QueryableProperty, Field.Model == Model.IDValue, Field.Value: Sendable
    {
        try await self.max(key, annotationContext: annotationContext).get()
    }
    
    func max<Field>(_ key: KeyPath<Model, Field>, annotationContext: SQLAnnotationContext? = nil) async throws -> Field.Value
        where Field: QueryableProperty, Field.Value: OptionalType & Sendable, Field.Model == Model
    {
        try await self.max(key, annotationContext: annotationContext).get()
    }
    
    func max<Field>(_ key: KeyPath<Model, Field>, annotationContext: SQLAnnotationContext? = nil) async throws -> Field.Value
        where Field: QueryableProperty, Field.Value: OptionalType & Sendable, Field.Model == Model.IDValue
    {
        try await self.max(key, annotationContext: annotationContext).get()
    }

    func aggregate<Field, Result>(
        _ method: DatabaseQuery.Aggregate.Method,
        _ field: KeyPath<Model, Field>,
        as type: Result.Type = Result.self,
        annotationContext: SQLAnnotationContext?  = nil
    ) async throws -> Result
        where Field: QueryableProperty, Field.Model == Model, Result: Codable & Sendable
    {
        try await self.aggregate(method, field, as: type, annotationContext: annotationContext).get()
    }
    
    func aggregate<Field, Result>(
        _ method: DatabaseQuery.Aggregate.Method,
        _ field: KeyPath<Model, Field>,
        as type: Result.Type = Result.self,
        annotationContext: SQLAnnotationContext?
    ) async throws -> Result
        where Field: QueryableProperty, Field.Model == Model.IDValue, Result: Codable & Sendable
    {
        try await self.aggregate(method, field, as: type, annotationContext: annotationContext).get()
    }
    
    func aggregate<Result>(
        _ method: DatabaseQuery.Aggregate.Method,
        _ field: FieldKey,
        as type: Result.Type = Result.self,
        annotationContext: SQLAnnotationContext?
    ) async throws -> Result
        where Result: Codable & Sendable
    {
        try await self.aggregate(method, field, as: type, annotationContext: annotationContext).get()
    }
    
    func aggregate<Result>(
        _ method: DatabaseQuery.Aggregate.Method,
        _ path: [FieldKey],
        as type: Result.Type = Result.self,
        annotationContext: SQLAnnotationContext?
    ) async throws -> Result
        where Result: Codable & Sendable
    {
        try await self.aggregate(method, path, as: type, annotationContext: annotationContext).get()
    }
    
    // MARK: - Paginate
    func paginate(
        _ request: PageRequest,
        annotationContext: SQLAnnotationContext?
    ) async throws -> Page<Model> {
        try await self.paginate(request, annotationContext: annotationContext).get()
    }
    
    func page(
        withIndex page: Int,
        size per: Int,
        annotationContext: SQLAnnotationContext?
    ) async throws -> Page<Model> {
        try await self.page(withIndex: page, size: per, annotationContext: annotationContext).get()
    }
}
