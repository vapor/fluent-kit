import Foundation
import AsyncKit
import Logging
import NIOCore

public struct Migrator {
    public let databaseFactory: (DatabaseID?) -> (Database)
    public let migrations: Migrations
    public let eventLoop: EventLoop
    public let migrationLogLevel: Logger.Level

    public init(
        databases: Databases,
        migrations: Migrations,
        logger: Logger,
        on eventLoop: EventLoop,
        migrationLogLevel: Logger.Level = .info
    ) {
        self.init(
            databaseFactory: {
                databases.database($0, logger: logger, on: eventLoop)!
            },
            migrations: migrations,
            on: eventLoop,
            migrationLogLevel: migrationLogLevel
        )
    }

    public init(
        databaseFactory: @escaping (DatabaseID?) -> (Database),
        migrations: Migrations,
        on eventLoop: EventLoop,
        migrationLogLevel: Logger.Level = .info
    ) {
        self.databaseFactory = databaseFactory
        self.migrations = migrations
        self.eventLoop = eventLoop
        self.migrationLogLevel = migrationLogLevel
    }
    
    // MARK: Setup
    
    public func setupIfNeeded() -> EventLoopFuture<Void> {
        return self.migrators() { $0.setupIfNeeded() }.transform(to: ())
    }
    
    // MARK: Prepare
    
    public func prepareBatch() -> EventLoopFuture<Void> {
        return self.migrators() { $0.prepareBatch() }.transform(to: ())
    }
    
    // MARK: Revert
    
    public func revertLastBatch() -> EventLoopFuture<Void> {
        return self.migrators() { $0.revertLastBatch() }.transform(to: ())
    }
    
    public func revertBatch(number: Int) -> EventLoopFuture<Void> {
        return self.migrators() { $0.revertBatch(number: number) }.transform(to: ())
    }
    
    public func revertAllBatches() -> EventLoopFuture<Void> {
        return self.migrators() { $0.revertAllBatches() }.transform(to: ())
    }
    
    // MARK: Preview
    
    public func previewPrepareBatch() -> EventLoopFuture<[(Migration, DatabaseID?)]> {
        return self.migrators() { migrator in
            return migrator.previewPrepareBatch().and(value: migrator.id)
        }.map { items in
            return items.reduce(into: []) { result, batch in
                let pairs = batch.0.map { ($0, batch.1) }
                result.append(contentsOf: pairs)
            }
        }
    }
    
    public func previewRevertLastBatch() -> EventLoopFuture<[(Migration, DatabaseID?)]> {
        return self.migrators() { migrator in
            return migrator.previewRevertLastBatch().and(value: migrator.id)
        }.map { items in
            return items.reduce(into: []) { result, batch in
                let pairs = batch.0.map { ($0, batch.1) }
                result.append(contentsOf: pairs)
            }
        }
    }
    
    public func previewRevertBatch() -> EventLoopFuture<[(Migration, DatabaseID?)]> {
        return self.migrators() { migrator in
            return migrator.previewPrepareBatch().and(value: migrator.id)
        }.map { items in
            return items.reduce(into: []) { result, batch in
                let pairs = batch.0.map { ($0, batch.1) }
                result.append(contentsOf: pairs)
            }
        }
    }
    
    public func previewRevertAllBatches() -> EventLoopFuture<[(Migration, DatabaseID?)]> {
        return self.migrators() { migrator in
            return migrator.previewRevertAllBatches().and(value: migrator.id)
        }.map { items in
            return items.reduce(into: []) { result, batch in
                let pairs = batch.0.map { ($0, batch.1) }
                result.append(contentsOf: pairs)
            }
        }
    }

    private func migrators<Result>(
        _ handler: (DatabaseMigrator) -> EventLoopFuture<Result>
    ) -> EventLoopFuture<[Result]> {
        return self.migrations.storage.map {
            handler(.init(id: $0, database: self.databaseFactory($0), migrations: $1, migrationLogLeveL: self.migrationLogLevel))
        }
        .flatten(on: self.eventLoop)
    }
}

private final class DatabaseMigrator {
    let migrations: [Migration]
    let database: Database
    let id: DatabaseID?
    let migrationLogLevel: Logger.Level

    init(id: DatabaseID?, database: Database, migrations: [Migration], migrationLogLeveL: Logger.Level) {
        self.migrations = migrations
        self.database = database
        self.id = id
        self.migrationLogLevel = migrationLogLeveL
    }

    // MARK: Setup

    func setupIfNeeded() -> EventLoopFuture<Void> {
        return MigrationLog.migration.prepare(on: self.database)
            .map(self.preventUnstableNames)
    }

    /// An unstable name is a name that is not the same every time migrations
    /// are run.
    ///
    /// For example, the default name for `Migrations` in private contexts
    /// will include an identifier that can change from one execution to the next.
    private func preventUnstableNames() {
        for migration in self.migrations
            where migration.name == migration.defaultName && migration.name.contains("$")
        {
            if migration.name.contains("unknown context at") {
                self.database.logger.critical("The migration at \(migration.name) is in a private context. Either explicitly give it a name by adding the `var name: String` property or make the migration `internal` or `public` instead of `private`.")
                fatalError("Private migrations not allowed")
            }
            self.database.logger.error("The migration at \(migration.name) has an unexpected default name. Consider giving it an explicit name by adding a `var name: String` property before applying these migrations.")
        }
    }

    // MARK: Prepare

    func prepareBatch() -> EventLoopFuture<Void> {
        return self.lastBatchNumber().flatMap { batch in
            self.unpreparedMigrations().sequencedFlatMapEach { self.prepare($0, batch: batch + 1) }
        }
    }

    // MARK: Revert

    func revertLastBatch() -> EventLoopFuture<Void> {
        return self.lastBatchNumber().flatMap(self.revertBatch(number:))
    }

    func revertBatch(number: Int) -> EventLoopFuture<Void> {
        return self.preparedMigrations(batch: number).sequencedFlatMapEach(self.revert)
    }

    func revertAllBatches() -> EventLoopFuture<Void> {
        return self.preparedMigrations().sequencedFlatMapEach(self.revert)
    }

    // MARK: Preview

    func previewPrepareBatch() -> EventLoopFuture<[Migration]> {
        return self.unpreparedMigrations()
    }

    func previewRevertLastBatch() -> EventLoopFuture<[Migration]> {
        return self.lastBatchNumber().flatMap { batch in
            return self.preparedMigrations(batch: batch)
        }
    }

    func previewRevertBatch(number: Int) -> EventLoopFuture<[Migration]> {
        return self.preparedMigrations(batch: number)
    }

    func previewRevertAllBatches() -> EventLoopFuture<[Migration]> {
        return self.preparedMigrations()
    }

    // MARK: Private

    private func prepare(_ migration: Migration, batch: Int) -> EventLoopFuture<Void> {
        self.database.logger.log(level: self.migrationLogLevel, "[Migrator] Starting prepare", metadata: ["migration": .string(migration.name)])
        return migration.prepare(on: self.database).flatMap {
            self.database.logger.log(level: self.migrationLogLevel, "[Migrator] Finished prepare", metadata: ["migration": .string(migration.name)])
            return MigrationLog(name: migration.name, batch: batch).save(on: self.database)
        }
    }

    private func revert(_ migration: Migration) -> EventLoopFuture<Void> {
        self.database.logger.log(level: self.migrationLogLevel, "[Migrator] Starting revert", metadata: ["migration": .string(migration.name)])
        return migration.revert(on: self.database).flatMap {
            self.database.logger.log(level: self.migrationLogLevel, "[Migrator] Finished revert", metadata: ["migration": .string(migration.name)])
            return MigrationLog.query(on: self.database).filter(\.$name == migration.name).delete()
        }
    }

    private func revertMigrationLog() -> EventLoopFuture<Void> {
        return MigrationLog.migration.revert(on: self.database)
    }

    private func lastBatchNumber() -> EventLoopFuture<Int> {
        return MigrationLog.query(on: self.database).sort(\.$batch, .descending).first().map { log in
            log?.batch ?? 0
        }
    }

    private func preparedMigrations() -> EventLoopFuture<[Migration]> {
        return MigrationLog.query(on: self.database).all().map { logs in
            return self.migrations.filter { migration in
                return logs.contains(where: { $0.name == migration.name })
            }.reversed()
        }
    }

    private func preparedMigrations(batch: Int) -> EventLoopFuture<[Migration]> {
        return MigrationLog.query(on: self.database).filter(\.$batch == batch).all().map { logs in
            return self.migrations.filter { migration in
                return logs.contains(where: { $0.name == migration.name })
            }.reversed()
        }
    }

    private func unpreparedMigrations() -> EventLoopFuture<[Migration]> {
        return MigrationLog.query(on: self.database).all().map { logs in
            return self.migrations.compactMap { migration in
                if logs.contains(where: { $0.name == migration.name }) { return nil }
                return migration
            }
        }
    }
}
