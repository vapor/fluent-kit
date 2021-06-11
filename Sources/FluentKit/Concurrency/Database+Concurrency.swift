#if compiler(>=5.5) && $AsyncAwait
import _NIOConcurrency

@available(macOS 9999, iOS 9999, watchOS 9999, tvOS 9999, *)
public extension Database {
    func transaction<T>(_ closure: @escaping (Database) async throws -> T) async throws -> T {
        try await self.transaction { db -> EventLoopFuture<T> in
            let promise = self.eventLoop.makePromise(of: T.self)
            promise.completeWithAsync{ try await closure(db) }
            return promise.futureResult
        }.get()
    }

    func withConnection<T>(_ closure: @escaping (Database) async throws -> T) async throws -> T {
        try await self.withConnection { db -> EventLoopFuture<T> in
            let promise = self.eventLoop.makePromise(of: T.self)
            promise.completeWithAsync{ try await closure(db) }
            return promise.futureResult
        }.get()
    }
}

#endif
