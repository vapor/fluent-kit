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
    
    public func setupIfNeeded(on databaseID: DatabaseID? = nil) -> EventLoopFuture<Void> {
        self.run(on: databaseID) { MigrationLog.migration.prepare(on: self.database($0)) }
    }
    
    // MARK: Prepare
    
    public func prepareBatch(on databaseID: DatabaseID? = nil) -> EventLoopFuture<Void> {
        self.run(on: databaseID) { database in
            self.unpreparedMigrations(on: database).flatMap { migrations in
                self.lastBatchNumber(on: database)
                    .and(value: migrations)
            }.flatMap { (lastBatch, migrations) in
                .andAllSync(migrations.map { item in
                    { self.prepare(item, batch: lastBatch + 1) }
                }, on: self.eventLoop)
            }
        }
    }
    
    // MARK: Revert
    
    public func revertLastBatch(on databaseID: DatabaseID? = nil) -> EventLoopFuture<Void> {
        self.run(on: databaseID) { database in
            self.lastBatchNumber(on: database).flatMap {
                self.revertBatch(number: $0, on: database)
            }
        }
    }
    
    public func revertBatch(number: Int, on databaseID: DatabaseID? = nil) -> EventLoopFuture<Void> {
        self.run(on: databaseID) { database in
            self.preparedMigrations(batch: number, on: database).flatMap { migrations in
                EventLoopFuture<Void>.andAllSync(migrations.map { item in
                    { self.revert(item) }
                }, on: self.eventLoop)
            }
        }
    }
    
    public func revertAllBatches(on databaseID: DatabaseID? = nil) -> EventLoopFuture<Void> {
        self.run(on: databaseID) { database in
            self.preparedMigrations(on: database).flatMap { migrations in
                .andAllSync(migrations.map { item in
                    { self.revert(item) }
                }, on: self.eventLoop)
            }.flatMap { _ in
                self.revertMigrationLog(on: database)
            }
        }
    }
    
    // MARK: Preview
    
    public func previewPrepareBatch(on databaseID: DatabaseID? = nil) -> EventLoopFuture<[(Migration, DatabaseID?)]> {
        var batch: [(Migration, DatabaseID?)] = []
        var failed: Error? = nil

        return self.run(on: databaseID) { database in
            self.unpreparedMigrations(on: database).map { items in
                batch.append(contentsOf: items.map { ($0.migration, $0.id)  })
            }.flatMapErrorThrowing { error in
                failed = error
            }
        }.flatMapThrowing {
            if let error = failed { throw error }
            return batch
        }
    }
    
    public func previewRevertLastBatch(on databaseID: DatabaseID? = nil) -> EventLoopFuture<[(Migration, DatabaseID?)]> {
        var batch: [(Migration, DatabaseID?)] = []
        var failed: Error? = nil

        return self.run(on: databaseID) { database in
            self.lastBatchNumber(on: database).flatMap { lastBatch in
                self.preparedMigrations(batch: lastBatch, on: database)
            }.map { items in
                batch.append(contentsOf: items.map { ($0.migration, $0.id)  })
            }.flatMapErrorThrowing { error in
                failed = error
            }
        }.flatMapThrowing {
            if let error = failed { throw error }
            return batch
        }
    }
    
    public func previewRevertBatch(number: Int, on databaseID: DatabaseID? = nil) -> EventLoopFuture<[(Migration, DatabaseID?)]> {
        var batch: [(Migration, DatabaseID?)] = []
        var failed: Error? = nil

        return self.run(on: databaseID) { database in
            self.preparedMigrations(on: database).map { items in
                batch.append(contentsOf: items.map { ($0.migration, $0.id)  })
            }.flatMapErrorThrowing { error in
                failed = error
            }
        }.flatMapThrowing {
            if let error = failed { throw error }
            return batch
        }
    }
    
    public func previewRevertAllBatches(on databaseID: DatabaseID? = nil) -> EventLoopFuture<[(Migration, DatabaseID?)]> {
        var batch: [(Migration, DatabaseID?)] = []
        var failed: Error? = nil

        return self.run(on: databaseID) { database in
            self.preparedMigrations(on: database).map { items in
                batch.append(contentsOf: items.map { ($0.migration, $0.id)  })
            }.flatMapErrorThrowing { error in
                failed = error
            }
        }.flatMapThrowing {
            if let error = failed { throw error }
            return batch
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
    
    private func revertMigrationLog(on databaseID: DatabaseID?) -> EventLoopFuture<Void> {
        MigrationLog.migration.revert(on: self.database(databaseID))
    }
    
    private func lastBatchNumber(on databaseID: DatabaseID?) -> EventLoopFuture<Int> {
        MigrationLog.query(on: self.database(databaseID)).sort(\.$batch, .descending).first().map { log in
            log?.batch ?? 0
        }
    }
    
    private func preparedMigrations(on databaseID: DatabaseID?) -> EventLoopFuture<[Migrations.Item]> {
        MigrationLog.query(on: self.database(databaseID)).all().map { logs -> [Migrations.Item] in
            self.migrations.storage.filter { storage in
                logs.contains { log in
                    storage.migration.name == log.name
                } && storage.id == databaseID
            }.reversed()
        }
    }
    
    private func preparedMigrations(batch: Int, on databaseID: DatabaseID?) -> EventLoopFuture<[Migrations.Item]> {
        MigrationLog.query(on: self.database(databaseID)).filter(\.$batch == batch).all().map { logs in
            self.migrations.storage.filter { storage in
                logs.contains { log in
                    storage.migration.name == log.name
                } && storage.id == databaseID
            }.reversed()
        }
    }
    
    private func unpreparedMigrations(on databaseID: DatabaseID?) -> EventLoopFuture<[Migrations.Item]> {
        return MigrationLog.query(on: self.database(databaseID))
            .all()
            .map
        { logs -> [Migrations.Item] in
            return self.migrations.storage.compactMap { item in
                if item.id == databaseID && logs.filter({ $0.name == item.migration.name }).count == 0 {
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

    private func run(on database: DatabaseID? = nil, _ query: @escaping (DatabaseID) -> EventLoopFuture<Void>) -> EventLoopFuture<Void> {
        if let id = database {
            return query(id)
        }

        let queries = self.migrations.databases.map { id -> () -> EventLoopFuture<Void> in
            return { query(id) }
        }

        return EventLoopFuture<Void>.andAllSync(queries, on: self.eventLoop)
    }
}

extension EventLoopFuture {
    public static func andAllSync(
        _ futures: [() -> EventLoopFuture<Void>],
        on eventLoop: EventLoop
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
