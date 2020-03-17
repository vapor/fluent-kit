import Foundation
import Logging
import AsyncKit

public struct Migrator {
    public let databaseFactory: (DatabaseID?) -> (Database)
    public let migrations: Migrations
    public let eventLoop: EventLoop
    
    public init(
        databases: Databases,
        migrations: Migrations,
        logger: Logger,
        on eventLoop: EventLoop
    ) {
        self.init(
            databaseFactory: {
                databases.database($0, logger: logger, on: eventLoop)!
            },
            migrations: migrations,
            on: eventLoop
        )
    }

    public init(
        databaseFactory: @escaping (DatabaseID?) -> (Database),
        migrations: Migrations,
        on eventLoop: EventLoop
    ) {
        self.databaseFactory = databaseFactory
        self.migrations = migrations
        self.eventLoop = eventLoop
    }
    
    // MARK: Setup
    
    public func setupIfNeeded() -> EventLoopFuture<Void> {
        MigrationLog.query(on: self.database(nil)).all().map { migrations in
            ()
        }.flatMapError { error in
            MigrationLog.migration.prepare(on: self.database(nil))
        }
    }
    
    // MARK: Prepare
    
    public func prepareBatch() -> EventLoopFuture<Void> {
        // Get last batch number and list of waiting migrations.
        return self.lastBatchNumber().flatMap { lastBatch in
            EventLoopFuture.and(
                self.unpreparedMigrations(stage: 1),
                self.unpreparedMigrations(stage: 2)
            ).flatMap {
                self.prepareBatch(stage1: $0, stage2: $1, as: lastBatch + 1)
            }
        }
    }
    
    // MARK: Revert
    
    public func revertLastBatch() -> EventLoopFuture<Void> {
        return self.lastBatchNumber().flatMap {
            self.revertBatch(number: $0)
        }
    }
    
    public func revertBatch(number: Int) -> EventLoopFuture<Void> {
        return EventLoopFuture.and(
            self.preparedMigrations(stage: 1, batch: number),
            self.preparedMigrations(stage: 2, batch: number)
        )
        .flatMap { self.revertBatch(stage1: $0, stage2: $1) }
    }
    
    public func revertAllBatches() -> EventLoopFuture<Void> {
        return EventLoopFuture.and(
            self.preparedMigrations(stage: 1, batch: nil),
            self.preparedMigrations(stage: 2, batch: nil)
        )
        .flatMap { self.revertBatch(stage1: $0, stage2: $1) }
        .flatMap { self.revertMigrationLog() }
    }
    
    // MARK: Preview
    
    public func previewPrepareBatch() -> EventLoopFuture<[(Migration, DatabaseID?)]> {
        EventLoopFuture.and(
            self.unpreparedMigrations(stage: 1),
            self.unpreparedMigrations(stage: 2)
        )
        .map { stage1, stage2 in
            // Append stage 2 to stage 1, but filter out names already in stage 1 first. This is as close as
            // this API can come to expressing the multi-stage behavior.
            stage1 + stage2.filter { i2 in !stage1.contains { i1 in i1.migration.name == i2.migration.name } }
        }
        .mapEach { ($0.migration, $0.id) }
    }
    
    public func previewRevertLastBatch() -> EventLoopFuture<[(Migration, DatabaseID?)]> {
        self.lastBatchNumber().flatMap { lastBatch in self.previewRevertBatch(lastBatch) }
    }
    
    public func previewRevertBatch(number: Int) -> EventLoopFuture<[(Migration, DatabaseID?)]> {
        self.previewRevertBatch(number)
    }
    
    public func previewRevertAllBatches() -> EventLoopFuture<[(Migration, DatabaseID?)]> {
        self.previewRevertBatch(nil)
    }
    
    // MARK: Private
    
    private func prepare(_ item: Migrations.Item, at stage: Int, as batch: Int) -> EventLoopFuture<Void> {
        let call = (stage == 1 ? item.migration.prepare(on:) : item.migration.prepareLate(on:))

        return call(self.database(item.id)).flatMap {
            MigrationLog(name: item.migration.name, stage: stage, batch: batch).save(on: self.database(nil))
        }
    }
    
    private func revert(_ item: Migrations.Item, at stage: Int) -> EventLoopFuture<Void> {
        let call = (stage == 1 ? item.migration.revert(on:) : item.migration.revertLate(on:))
        
        return call(self.database(item.id)).flatMap {
            MigrationLog.query(on: self.database(nil))
                .filter(\.$name == item.migration.name)
                .filter(\.$stage == stage)
                .delete()
        }
    }
    
    private func prepareBatch(stage1: [Migrations.Item], stage2: [Migrations.Item], as nextBatch: Int) -> EventLoopFuture<Void> {
        let queue = EventLoopFutureQueue(eventLoop: self.eventLoop)
    
        // Queue stage 1 migrations and their logs, then stage 2 migrations and their logs.
        _ = queue.append(each: stage1, { item in self.prepare(item, at: 1, as: nextBatch) })
        _ = queue.append(each: stage2, { item in self.prepare(item, at: 2, as: nextBatch) })
        
        // Add a trailer future to the queue for cleanliness.
        return queue.append(self.eventLoop.future(), runningOn: .success)
    }
    
    private func revertBatch(stage1: [Migrations.Item], stage2: [Migrations.Item]) -> EventLoopFuture<Void> {
        let queue = EventLoopFutureQueue(eventLoop: self.eventLoop)
        
        // Revert stage 2 first, then stage 1. Don't reverse the arrays, that was done by `preparedMigrations()`.
        _ = queue.append(each: stage2, { item in self.revert(item, at: 2) })
        _ = queue.append(each: stage1, { item in self.revert(item, at: 1) })
        
        // And as before a cleanliness trailer.
        return queue.append(self.eventLoop.future(), runningOn: .success)
    }
    
    private func previewRevertBatch(_ number: Int?) -> EventLoopFuture<[(Migration, DatabaseID?)]> {
        return EventLoopFuture.and(
            self.preparedMigrations(stage: 1, batch: number),
            self.preparedMigrations(stage: 2, batch: number)
        )
        .map { stage1, stage2 in
            stage2 + stage1.filter { i1 in !stage2.contains { i2 in i1.migration.name == i2.migration.name } }
        }
        .mapEach { ($0.migration, $0.id) }
    }
    
    private func revertMigrationLog() -> EventLoopFuture<Void> {
        MigrationLog.migration.revert(on: self.database(nil))
    }
    
    private func lastBatchNumber() -> EventLoopFuture<Int> {
        MigrationLog.query(on: self.database(nil)).sort(\.$batch, .descending).first().map { $0?.batch ?? 0 }
    }
    
    private func storedMigrations(matching names: [String], inverted: Bool) -> [Migrations.Item] {
        // This is a kinda yucky O(n^2) a lot of the time...
        return self.migrations.storage.filter { item in
            // Logic matrix:
            // - Contains: True   Inverted: False   Result: True   (does contain)
            // - Contains: False  Inverted: False   Result: False  (does not contain)
            // - Contains: True   Inverted: True    Result: False  (does not exclude)
            // - Contains: False  Inverted: True    Result: True   (does exclude)
            // Basically, it's an XOR operation, except you can't do that with Bool.
            return names.contains(item.migration.name) ? !inverted : inverted
        }
    }
    
    private func preparedMigrations(stage: Int, batch: Int?) -> EventLoopFuture<[Migrations.Item]> {
        MigrationLog.query(on: self.database(nil))
            .group(.and, { q in _ = batch.map { q.filter(\.$batch == $0) } })
            .filter(\.$stage == stage)
            .sort(\.$batch)
            .all(\.$name)
            .map { self.storedMigrations(matching: $0, inverted: false).reversed() }
    }
    
    private func unpreparedMigrations(stage: Int) -> EventLoopFuture<[Migrations.Item]> {
        return MigrationLog.query(on: self.database(nil))
            .filter(\.$stage == stage)
            .all(\.$name)
            .map { self.storedMigrations(matching: $0, inverted: true) }
    }
    
    private func database(_ id: DatabaseID?) -> Database {
        self.databaseFactory(id)
    }
}

extension EventLoopFuture {
    
    /// Alternative syntax for `first.and(second)`.
    public static func and<B>(_ first: EventLoopFuture<Value>, _ second: EventLoopFuture<B>) -> EventLoopFuture<(Value, B)> {
        return first.and(second)
    }

}
