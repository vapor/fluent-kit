import NIOCore

public protocol AsyncMigration: Migration {
    func prepare(on database: Database) async throws
    func revert(on database: Database) async throws
}

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
