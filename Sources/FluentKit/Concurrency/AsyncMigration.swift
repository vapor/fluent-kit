#if compiler(>=5.5) && $AsyncAwait
import _NIOConcurrency

public protocol AsyncMigration: Migration {
    func prepare(on database: Database) async throws
    func revert(on database: Database) async throws
}

@available(macOS 9999, iOS 9999, watchOS 9999, tvOS 9999, *)
public extension AsyncMigration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        let promise = database.eventLoop.makePromise(of: Void.self)
        promise.completeWithAsync {
            try await self.prepare(on: database)
        }
        return promise.futureResult
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        let promise = database.eventLoop.makePromise(of: Void.self)
        promise.completeWithAsync {
            try await self.revert(on: database)
        }
        return promise.futureResult
    }
}

#endif

