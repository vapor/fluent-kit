#if compiler(>=5.5)
import _NIOConcurrency

@available(macOS 12, iOS 15, watchOS 8, tvOS 15, *)
public protocol AsyncMigration: Migration {
    func prepare(on database: Database) async throws
    func revert(on database: Database) async throws
}

@available(macOS 12, iOS 15, watchOS 8, tvOS 15, *)
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

