import NIOCore

public protocol AsyncMigration: Migration {
    func prepare(on database: any Database) async throws
    func revert(on database: any Database) async throws
}

public extension AsyncMigration {
    func prepare(on database: any Database) -> EventLoopFuture<Void> {
        database.eventLoop.makeFutureWithTask {
            try await self.prepare(on: database)
        }
    }
    
    func revert(on database: any Database) -> EventLoopFuture<Void> {
        database.eventLoop.makeFutureWithTask {
            try await self.revert(on: database)
        }
    }
}
