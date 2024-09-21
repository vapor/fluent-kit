import NIOCore

public extension Database {
    func execute(
        query: DatabaseQuery,
        onOutput: @escaping @Sendable (any DatabaseOutput) -> ()
    ) async throws {
        try await self.execute(query: query, onOutput: onOutput).get()
    }

    func execute(
        schema: DatabaseSchema
    ) async throws {
        try await self.execute(schema: schema).get()
    }

    func execute(
        enum: DatabaseEnum
    ) async throws {
        try await self.execute(enum: `enum`).get()
    }

    func transaction<T>(_ closure: @escaping @Sendable (any Database) async throws -> T) async throws -> T {
        try await self.transaction { db in
            self.eventLoop.makeFutureWithTask {
                try await closure(db)
            }
        }.get()
    }

    func withConnection<T>(_ closure: @escaping @Sendable (any Database) async throws -> T) async throws -> T {
        try await self.withConnection { db in
            self.eventLoop.makeFutureWithTask {
                try await closure(db)
            }
        }.get()
    }
}
