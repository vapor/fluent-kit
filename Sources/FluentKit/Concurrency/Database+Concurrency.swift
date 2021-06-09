#if compiler(>=5.5) && $AsyncAwait
import _NIOConcurrency

@available(macOS 9999, iOS 9999, watchOS 9999, tvOS 9999, *)
public extension Database {
    func transaction<T>(_ closure: @escaping (Database) -> EventLoopFuture<T>) async throws -> T {
        try await self.transaction(closure).get()
    }

    func withConnection<T>(_ closure: @escaping (Database) -> EventLoopFuture<T>) async throws -> T {
        try await self.withConnection(closure).get()
    }
}

#endif
