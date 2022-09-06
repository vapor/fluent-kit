#if compiler(>=5.5) && canImport(_Concurrency)
import NIOCore

@available(macOS 10.15, iOS 13, tvOS 13, watchOS 6, *)
public protocol AsyncMigration: Migration {
    func prepare(on database: Database) async throws
    func revert(on database: Database) async throws
}

@available(macOS 10.15, iOS 13, tvOS 13, watchOS 6, *)
public extension AsyncMigration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        let promise = database.eventLoop.makePromise(of: Void.self)
        promise.completeWithTask {
            try await self.prepare(on: database)
        }
        return promise.futureResult
    }
    
    func revert(on database: Database) -> EventLoopFuture<Void> {
        let promise = database.eventLoop.makePromise(of: Void.self)
        promise.completeWithTask {
            try await self.revert(on: database)
        }
        return promise.futureResult
    }
}

#endif

