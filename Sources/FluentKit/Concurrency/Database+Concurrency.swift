import NIOCore

public extension Database {
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
