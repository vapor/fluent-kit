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
        return self.lastBatchNumber().and(self.unpreparedMigrations()).flatMap { lastBatch, migrations in
            let queue = EventLoopFutureQueue(eventLoop: self.eventLoop)
        
            // Queue up the waiting migrations (first stage).
            _ = queue.append(each: migrations, { item in
                return item.migration.prepare(on: self.database(item.id))
            })
            
            // Queue up the waiting migrations again (second stage) and save migration log.
            _ = queue.append(each: migrations, { item in
                return item.migration.prepareLate(on: self.database(item.id)).flatMap {
                    MigrationLog(name: item.migration.name, batch: lastBatch + 1).save(on: self.database(nil))
                }
            })
            
            // Add a trailer future to the queue for cleanliness.
            return queue.append { self.eventLoop.future() }
        }
    }
    
    // MARK: Revert
    
    public func revertLastBatch() -> EventLoopFuture<Void> {
        return self.lastBatchNumber().flatMap {
            self.revertBatch(number: $0)
        }
    }
    
    public func revertBatch(number: Int) -> EventLoopFuture<Void> {
        return self.preparedMigrations(batch: number)
                   .flatMap { self.revertMigrationList($0) }
    }
    
    public func revertAllBatches() -> EventLoopFuture<Void> {
        return self.preparedMigrations()
           .flatMap { self.revertMigrationList($0) }
           .flatMap { self.revertMigrationLog() }
    }
    
    private func revertMigrationList(_ migrations: [Migrations.Item]) -> EventLoopFuture<Void> {
        let queue = EventLoopFutureQueue(eventLoop: self.eventLoop)
    
        // Queue up stage 2 revert first (reverse of prepare).
        _ = queue.append(each: migrations, { item in
            item.migration.revertLate(on: self.database(item.id))
        })
        
        // Queue up stage 1 revert and delete migration log.
        _ = queue.append(each: migrations, { item in
            return item.migration.revert(on: self.database(item.id)).flatMap {
                MigrationLog.query(on: self.database(nil)).filter(\.$name == item.migration.name).delete()
            }
        })
        
        // And as before a cleanliness trailer.
        return queue.append { self.eventLoop.future() }
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
            self.migrations.storage.filter { storage in
                logs.contains { log in
                    storage.migration.name == log.name
                }
            }.reversed()
        }
    }
    
    private func preparedMigrations(batch: Int) -> EventLoopFuture<[Migrations.Item]> {
        MigrationLog.query(on: self.database(nil)).filter(\.$batch == batch).all().map { logs in
            self.migrations.storage.filter { storage in
                logs.contains { log in
                    storage.migration.name == log.name
                }
            }.reversed()
        }
    }
    
    private func unpreparedMigrations() -> EventLoopFuture<[Migrations.Item]> {
        return MigrationLog.query(on: self.database(nil))
            .all()
            .map
        { logs -> [Migrations.Item] in
            // This is a kinda yucky O(n^2) if migrations are already run, but settles at or near
            // O(n) for the case where none have run yet.
            return self.migrations.storage.filter { item in
                !logs.contains(where: { $0.name == item.migration.name })
            }
        }
    }
    
    private func database(_ id: DatabaseID?) -> Database {
        self.databaseFactory(id)
    }
}
