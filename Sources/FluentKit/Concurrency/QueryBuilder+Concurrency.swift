#if compiler(>=5.5) && $AsyncAwait
 import _NIOConcurrency

 @available(macOS 9999, iOS 9999, watchOS 9999, tvOS 9999, *)
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
        where
            Field: QueryableProperty,
            Field.Model == Model
    {
        try await self.all(key).get()
    }

    func all<Joined, Field>(
        _ joined: Joined.Type,
        _ field: KeyPath<Joined, Field>
    ) async throws -> [Field.Value]
        where
            Joined: Schema,
            Field: QueryableProperty,
            Field.Model == Joined
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
 }

 #endif
