import NIOCore

public extension Database {
    func transaction<T>(_ closure: @Sendable @escaping (any Database) async throws -> T) async throws -> T {
        try await self.transaction { db -> EventLoopFuture<T> in
            self.eventLoop.makeFutureWithTask {
                try await closure(db)
            }
        }.get()
    }

    func withConnection<T>(_ closure: @Sendable @escaping (any Database) async throws -> T) async throws -> T {
        try await self.withConnection { db -> EventLoopFuture<T> in
            self.eventLoop.makeFutureWithTask {
                try await closure(db)
            }
        }.get()
    }
}
