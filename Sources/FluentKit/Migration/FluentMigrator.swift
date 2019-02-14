import Foundation

public struct FluentMigrator {
    public let migrations: FluentMigrations
    public let databases: FluentDatabases
    public let eventLoop: EventLoop
    
    public init(databases: FluentDatabases, migrations: FluentMigrations, on eventLoop: EventLoop) {
        self.databases = databases
        self.migrations = migrations
        self.eventLoop = eventLoop
    }
    
    
    #warning("TODO: handle identical migration added to two dbs")
    
    // MARK: Prepare
    
    public func prepareBatch() -> EventLoopFuture<Void> {
        return self.prepareMigrationLogIfNeeded().flatMap { _ -> EventLoopFuture<Void> in
            return self.unpreparedMigrations().flatMap { migrations in
                return .andAllSync(migrations.map { item in
                    return { self.prepare(item) }
                }, eventLoop: self.eventLoop)
            }
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
    
    public func previewPrepareBatch() -> EventLoopFuture<[(FluentMigration, FluentDatabaseID?)]> {
        return self.unpreparedMigrations().map { items -> [(FluentMigration, FluentDatabaseID?)] in
            return items.map { item -> (FluentMigration, FluentDatabaseID?) in
                return (item.migration, item.id)
            }
        }
    }
    
    public func previewRevertLastBatch() -> EventLoopFuture<[(FluentMigration, FluentDatabaseID?)]> {
        return self.lastBatchNumber().flatMap { lastBatch in
            return self.preparedMigrations(batch: lastBatch)
        }.map { items -> [(FluentMigration, FluentDatabaseID?)] in
            return items.map { item -> (FluentMigration, FluentDatabaseID?) in
                return (item.migration, item.id)
            }
        }
    }
    
    public func previewRevertBatch(number: Int) -> EventLoopFuture<[(FluentMigration, FluentDatabaseID?)]> {
        return self.preparedMigrations(batch: number).map { items -> [(FluentMigration, FluentDatabaseID?)] in
            return items.map { item -> (FluentMigration, FluentDatabaseID?) in
                return (item.migration, item.id)
            }
        }
    }
    
    public func previewRevertAllBatches() -> EventLoopFuture<[(FluentMigration, FluentDatabaseID?)]> {
        return self.preparedMigrations().map { items -> [(FluentMigration, FluentDatabaseID?)] in
            return items.map { item -> (FluentMigration, FluentDatabaseID?) in
                return (item.migration, item.id)
            }
        }
    }
    
    // MARK: Private
    
    private func prepare(_ item: FluentMigrations.Item) -> EventLoopFuture<Void> {
        let database: FluentDatabase
        if let id = item.id {
            #warning("TODO: fix force unwrap")
            database = self.databases.database(id)!
        } else {
            database = self.databases.default()
        }
        return item.migration.prepare(on: database).flatMap {
            let log = MigrationLog.new()
            log.name.set(to: item.migration.name)
            log.batch.set(to: 1)
            #warning("TODO: Timestampable")
            log.createdAt.set(to: .init())
            log.updatedAt.set(to: .init())
            return log.save(on: self.databases.default())
        }
    }
    
    private func prepareMigrationLogIfNeeded() -> EventLoopFuture<Void> {
        return self.databases.default().query(MigrationLog.self).all().map { migrations in
            return ()
        }.flatMapError { error in
            return MigrationLog.autoMigration().prepare(on: self.databases.default())
        }
    }
    
    private func revert(_ item: FluentMigrations.Item) -> EventLoopFuture<Void> {
        let database: FluentDatabase
        if let id = item.id {
            #warning("TODO: fix force unwrap")
            database = self.databases.database(id)!
        } else {
            database = self.databases.default()
        }
        return item.migration.revert(on: database).flatMap {
            return self.databases.default().query(MigrationLog.self)
                .filter(\.name == item.migration.name)
                .delete()
        }
    }
    
    private func revertMigrationLog() -> EventLoopFuture<Void> {
        return MigrationLog.autoMigration().revert(on: self.databases.default())
    }
    
    private func lastBatchNumber() -> EventLoopFuture<Int> {
        #warning("TODO: use db sorting")
        return self.databases.default().query(MigrationLog.self).all().flatMapThrowing { logs in
            return try logs.sorted(by: { try $0.batch.get() > $1.batch.get() })
                .first?.batch.get() ?? 0
        }
    }
    
    private func preparedMigrations() -> EventLoopFuture<[FluentMigrations.Item]> {
        return self.databases.default().query(MigrationLog.self).all().flatMapThrowing { logs -> [FluentMigrations.Item] in
            return try logs.compactMap { log in
                if let item = try self.migrations.storage.filter({ try $0.migration.name == log.name.get() }).first {
                    return item
                } else {
                    print("No registered migration found for \(log.name)")
                    return nil
                }
            }.reversed()
        }
    }
    
    private func preparedMigrations(batch: Int) -> EventLoopFuture<[FluentMigrations.Item]> {
        return self.databases.default().query(MigrationLog.self).filter(\.batch == batch).all().flatMapThrowing { logs -> [FluentMigrations.Item] in
            return try logs.compactMap { log in
                if let item = try self.migrations.storage.filter({ try $0.migration.name == log.name.get() }).first {
                    return item
                } else {
                    print("No registered migration found for \(log.name)")
                    return nil
                }
            }.reversed()
        }
    }
    
    private func unpreparedMigrations() -> EventLoopFuture<[FluentMigrations.Item]> {
        return self.databases.default().query(MigrationLog.self).all().flatMapThrowing { logs -> [FluentMigrations.Item] in
            return try self.migrations.storage.compactMap { item in
                if try logs.filter({ try $0.name.get() == item.migration.name }).count == 0 {
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
