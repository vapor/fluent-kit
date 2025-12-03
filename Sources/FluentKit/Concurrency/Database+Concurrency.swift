import NIOCore

extension Database {
    public func execute(
        query: DatabaseQuery,
        onOutput: @escaping @Sendable (any DatabaseOutput) -> Void
    ) async throws {
        try await self.execute(query: query, onOutput: onOutput).get()
    }

    public func execute(
        schema: DatabaseSchema
    ) async throws {
        try await self.execute(schema: schema).get()
    }

    public func execute(
        enum: DatabaseEnum
    ) async throws {
        try await self.execute(enum: `enum`).get()
    }

    public func transaction<T: Sendable>(_ closure: @escaping @Sendable (any Database) async throws -> T) async throws -> T {
        try await self.transaction { db in
            self.eventLoop.makeFutureWithTask {
                try await closure(db)
            }
        }.get()
    }

    public func withConnection<T: Sendable>(_ closure: @escaping @Sendable (any Database) async throws -> T) async throws -> T {
        try await self.withConnection { db in
            self.eventLoop.makeFutureWithTask {
                try await closure(db)
            }
        }.get()
    }
}
