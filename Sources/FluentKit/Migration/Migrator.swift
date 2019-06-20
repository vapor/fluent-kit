import Foundation

public struct Migrator {
    public var migrations: Migrations
    public var databases: Databases
    public let eventLoop: EventLoop
    
    public init(databases: Databases, migrations: Migrations, on eventLoop: EventLoop) {
        self.databases = databases
        self.migrations = migrations
        self.eventLoop = eventLoop
    }
    
    // MARK: Setup
    
    public func setupIfNeeded() -> EventLoopFuture<Void> {
        return MigrationLog.query(on: self.databases.default()).all().map { migrations in
            return ()
        }.flatMapError { error in
            return MigrationLog.autoMigration().prepare(on: self.databases.default())
        }
    }
    
    // MARK: Prepare
    
    public func prepareBatch() -> EventLoopFuture<Void> {
        return self.unpreparedMigrations().flatMap { migrations in
            return self.lastBatchNumber()
                .and(value: migrations)
        }.flatMap { (lastBatch, migrations) in
            return .andAllSync(migrations.map { item in
                return { self.prepare(item, batch: lastBatch + 1) }
            }, eventLoop: self.eventLoop)
        }
    }
    
    // MARK: Revert
    
    public func revertLastBatch() -> EventLoopFuture<Void> {
        return self.lastBatchNumber().flatMap { self.revertBatch(number: $0) }
    }
    
    public func revertBatch(number: Int) -> EventLoopFuture<Void> {
        return self.preparedMigrations(batch: number).flatMap { migrations in
            return EventLoopFuture<Void>.andAllSync(migrations.map { item in
                return { self.revert(item) }
            }, eventLoop: self.eventLoop)
        }
    }
    
    public func revertAllBatches() -> EventLoopFuture<Void> {
        return self.preparedMigrations().flatMap { migrations in
            return EventLoopFuture<Void>.andAllSync(migrations.map { item in
                return { self.revert(item) }
            }, eventLoop: self.eventLoop)
        }.flatMap { _ in
            return self.revertMigrationLog()
        }
    }
    
    // MARK: Preview
    
    public func previewPrepareBatch() -> EventLoopFuture<[(Migration, DatabaseID?)]> {
        return self.unpreparedMigrations().map { items -> [(Migration, DatabaseID?)] in
            return items.map { item -> (Migration, DatabaseID?) in
                return (item.migration, item.id)
            }
        }
    }
    
    public func previewRevertLastBatch() -> EventLoopFuture<[(Migration, DatabaseID?)]> {
        return self.lastBatchNumber().flatMap { lastBatch in
            return self.preparedMigrations(batch: lastBatch)
        }.map { items -> [(Migration, DatabaseID?)] in
            return items.map { item -> (Migration, DatabaseID?) in
                return (item.migration, item.id)
            }
        }
    }
    
    public func previewRevertBatch(number: Int) -> EventLoopFuture<[(Migration, DatabaseID?)]> {
        return self.preparedMigrations(batch: number).map { items -> [(Migration, DatabaseID?)] in
            return items.map { item -> (Migration, DatabaseID?) in
                return (item.migration, item.id)
            }
        }
    }
    
    public func previewRevertAllBatches() -> EventLoopFuture<[(Migration, DatabaseID?)]> {
        return self.preparedMigrations().map { items -> [(Migration, DatabaseID?)] in
            return items.map { item -> (Migration, DatabaseID?) in
                return (item.migration, item.id)
            }
        }
    }
    
    // MARK: Private
    
    private func prepare(_ item: Migrations.Item, batch: Int) -> EventLoopFuture<Void> {
        let database: Database
        if let id = item.id {
            database = self.databases.database(id)!
        } else {
            database = self.databases.default()
        }
        return item.migration.prepare(on: database).flatMap {
            return MigrationLog(name: item.migration.name, batch: batch)
                .save(on: self.databases.default())
        }
    }
    
    private func revert(_ item: Migrations.Item) -> EventLoopFuture<Void> {
        let database: Database
        if let id = item.id {
            database = self.databases.database(id)!
        } else {
            database = self.databases.default()
        }
        return item.migration.revert(on: database).flatMap { _ -> EventLoopFuture<Void> in
            return MigrationLog.query(on: self.databases.default())
                .filter(\.$name == item.migration.name)
                .delete()
        }
    }
    
    private func revertMigrationLog() -> EventLoopFuture<Void> {
        return MigrationLog.autoMigration().revert(on: self.databases.default())
    }
    
    private func lastBatchNumber() -> EventLoopFuture<Int> {
        return MigrationLog.query(on: self.databases.default()).sort(\.$batch, .descending).first().map { log in
            return log?.batch ?? 0
        }
    }
    
    private func preparedMigrations() -> EventLoopFuture<[Migrations.Item]> {
        return MigrationLog.query(on: self.databases.default()).all().map { logs -> [Migrations.Item] in
            return logs.compactMap { log in
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
        return MigrationLog.query(on: self.databases.default()).filter(\.$batch == batch).all().map { logs -> [Migrations.Item] in
            return logs.compactMap { log in
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
        return MigrationLog.query(on: self.databases.default()).all().map { logs -> [Migrations.Item] in
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
