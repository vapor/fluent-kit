import FluentKit

final class ErrorMigration: Migration {
    init() { }
    
    struct Error: Swift.Error { }
    
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        return database.eventLoop.makeFailedFuture(Error())
    }
    
    func revert(on database: Database) -> EventLoopFuture<Void> {
        return database.eventLoop.makeSucceededFuture(())
    }
}
