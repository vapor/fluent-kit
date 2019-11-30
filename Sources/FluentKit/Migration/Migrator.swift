import Foundation
import Logging

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

    init(
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
        self.unpreparedMigrations().flatMap { migrations in
            self.lastBatchNumber()
                .and(value: migrations)
        }.flatMap { (lastBatch, migrations) in
            .andAllSync(migrations.map { item in
                { self.prepare(item, batch: lastBatch + 1) }
            }, eventLoop: self.eventLoop)
        }
    }
    
    // MARK: Revert
    
    public func revertLastBatch() -> EventLoopFuture<Void> {
        self.lastBatchNumber().flatMap {
            self.revertBatch(number: $0)
        }
    }
    
    public func revertBatch(number: Int) -> EventLoopFuture<Void> {
        self.preparedMigrations(batch: number).flatMap { migrations in
            EventLoopFuture<Void>.andAllSync(migrations.map { item in
                { self.revert(item) }
            }, eventLoop: self.eventLoop)
        }
    }
    
    public func revertAllBatches() -> EventLoopFuture<Void> {
        self.preparedMigrations().flatMap { migrations in
            .andAllSync(migrations.map { item in
                { self.revert(item) }
            }, eventLoop: self.eventLoop)
        }.flatMap { _ in
            self.revertMigrationLog()
        }
    }
    
    // MARK: Preview
    
    public func previewPrepareBatch() -> EventLoopFuture<[(Migration, DatabaseID?)]> {
        self.unpreparedMigrations().map { items in
            items.map { item  in
                (item.migration, item.id)
            }
        }
    }
    
    public func previewRevertLastBatch() -> EventLoopFuture<[(Migration, DatabaseID?)]> {
        self.lastBatchNumber().flatMap { lastBatch in
            self.preparedMigrations(batch: lastBatch)
        }.map { items in
            items.map { item in
                (item.migration, item.id)
            }
        }
    }
    
    public func previewRevertBatch(number: Int) -> EventLoopFuture<[(Migration, DatabaseID?)]> {
        self.preparedMigrations(batch: number).map { items -> [(Migration, DatabaseID?)] in
            items.map { item -> (Migration, DatabaseID?) in
                return (item.migration, item.id)
            }
        }
    }
    
    public func previewRevertAllBatches() -> EventLoopFuture<[(Migration, DatabaseID?)]> {
        self.preparedMigrations().map { items -> [(Migration, DatabaseID?)] in
            items.map { item -> (Migration, DatabaseID?) in
                return (item.migration, item.id)
            }
        }
    }
    
    // MARK: Private
    
    private func prepare(_ item: Migrations.Item, batch: Int) -> EventLoopFuture<Void> {
        item.migration.prepare(on: self.database(item.id)).flatMap {
            MigrationLog(name: item.migration.name, batch: batch)
                .save(on: self.database(nil))
        }
    }
    
    private func revert(_ item: Migrations.Item) -> EventLoopFuture<Void> {
        item.migration.revert(on: self.database(item.id)).flatMap {
            MigrationLog.query(on: self.database(nil))
                .filter(\.$name == item.migration.name)
                .delete()
        }
    }
    
    private func revertMigrationLog() -> EventLoopFuture<Void> {
        MigrationLog.migration.revert(on: self.database(nil))
    }
    
    private func lastBatchNumber() -> EventLoopFuture<Int> {
        MigrationLog.query(on: self.database(nil)).sort(\.$batch, .descending).first().map { log in
            log?.batch ?? 0
        }
    }
    
    private func preparedMigrations() -> EventLoopFuture<[Migrations.Item]> {
        MigrationLog.query(on: self.database(nil)).all().map { logs -> [Migrations.Item] in
            logs.compactMap { log in
                if let item = self.migrations.storage.filter({ $0.migration.name == log.name }).first {
                    return item
                } else {
                    print("No registered migration found for \(log.name)")
                    return nil
                }
            }.reversed()
        }
    }
    
    private func preparedMigrations(batch: Int) -> EventLoopFuture<[Migrations.Item]> {
        MigrationLog.query(on: self.database(nil)).filter(\.$batch == batch).all().map { logs in
            logs.compactMap { log in
                if let item = self.migrations.storage.filter({ $0.migration.name == log.name }).first {
                    return item
                } else {
                    print("No registered migration found for \(log.name)")
                    return nil
                }
            }.reversed()
        }
    }
    
    private func unpreparedMigrations() -> EventLoopFuture<[Migrations.Item]> {
        return MigrationLog.query(on: self.database(nil)).all().map { logs -> [Migrations.Item] in
            return self.migrations.storage.compactMap { item in
                if logs.filter({ $0.name == item.migration.name }).count == 0 {
                    return item
                } else {
                    // log found, this has been prepared
                    return nil
                }
            }
        }
    }
    
    private func database(_ id: DatabaseID?) -> Database {
        self.databaseFactory(id)
    }
}

private extension EventLoopFuture {
    static func andAllSync(
        _ futures: [() -> EventLoopFuture<Void>],
        eventLoop: EventLoop
    ) -> EventLoopFuture<Void> {
        let promise = eventLoop.makePromise(of: Void.self)
        
        var iterator = futures.makeIterator()
        func handle(_ future: () -> EventLoopFuture<Void>) {
            future().whenComplete { res in
                switch res {
                case .success:
                    if let next = iterator.next() {
                        handle(next)
                    } else {
                        promise.succeed(())
                    }
                case .failure(let error):
                    promise.fail(error)
                }
            }
        }
        
        if let first = iterator.next() {
            handle(first)
        } else {
            promise.succeed(())
        }
        
        return promise.futureResult
    }
}
