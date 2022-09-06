#if compiler(>=5.5) && canImport(_Concurrency)
import NIOCore

@available(macOS 10.15, iOS 13, tvOS 13, watchOS 6, *)
public extension Database {
    func transaction<T>(_ closure: @Sendable @escaping (Database) async throws -> T) async throws -> T {
        try await self.transaction { db -> EventLoopFuture<T> in
            let promise = self.eventLoop.makePromise(of: T.self)
            promise.completeWithTask{ try await closure(db) }
            return promise.futureResult
        }.get()
    }

    func withConnection<T>(_ closure: @Sendable @escaping (Database) async throws -> T) async throws -> T {
        try await self.withConnection { db -> EventLoopFuture<T> in
            let promise = self.eventLoop.makePromise(of: T.self)
            promise.completeWithTask{ try await closure(db) }
            return promise.futureResult
        }.get()
    }
}

#endif
