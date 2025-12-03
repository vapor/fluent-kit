import Foundation
import Logging
import NIOConcurrencyHelpers
import NIOCore

public struct Migrator: Sendable {
    public let databaseFactory: @Sendable (DatabaseID?) -> (any Database)
    public let migrations: Migrations
    public let eventLoop: any EventLoop
    public let migrationLogLevel: Logger.Level

    public init(
        databases: Databases,
        migrations: Migrations,
        logger: Logger,
        on eventLoop: any EventLoop,
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
        databaseFactory: @escaping @Sendable (DatabaseID?) -> (any Database),
        migrations: Migrations,
        on eventLoop: any EventLoop,
        migrationLogLevel: Logger.Level = .info
    ) {
        self.databaseFactory = databaseFactory
        self.migrations = migrations
        self.eventLoop = eventLoop
        self.migrationLogLevel = migrationLogLevel
    }

    // MARK: Setup

    public func setupIfNeeded() -> EventLoopFuture<Void> {
        self.migrators { $0.setupIfNeeded() }.map { _ in }
    }

    // MARK: Prepare

    public func prepareBatch() -> EventLoopFuture<Void> {
        self.migrators { $0.prepareBatch() }.map { _ in }
    }

    // MARK: Revert

    public func revertLastBatch() -> EventLoopFuture<Void> {
        self.migrators { $0.revertLastBatch() }.map { _ in }
    }

    public func revertBatch(number: Int) -> EventLoopFuture<Void> {
        self.migrators { $0.revertBatch(number: number) }.map { _ in }
    }

    public func revertAllBatches() -> EventLoopFuture<Void> {
        self.migrators { $0.revertAllBatches() }.map { _ in }
    }

    // MARK: Preview

    public func previewPrepareBatch() -> EventLoopFuture<[(any Migration, DatabaseID?)]> {
        self.migrators { migrator in
            migrator.previewPrepareBatch().and(value: migrator.id)
        }.map {
            $0.flatMap { migrations, id in migrations.map { ($0, id) } }
        }
    }

    public func previewRevertLastBatch() -> EventLoopFuture<[(any Migration, DatabaseID?)]> {
        self.migrators { migrator in
            migrator.previewRevertLastBatch().and(value: migrator.id)
        }.map {
            $0.flatMap { migrations, id in migrations.map { ($0, id) } }
        }
    }

    public func previewRevertBatch() -> EventLoopFuture<[(any Migration, DatabaseID?)]> {
        self.migrators { migrator in
            // This is not correct, but can't be fixed as it would require changing this API's parameters.
            migrator.previewPrepareBatch().and(value: migrator.id)
        }.map {
            $0.flatMap { migrations, id in migrations.map { ($0, id) } }
        }
    }

    public func previewRevertAllBatches() -> EventLoopFuture<[(any Migration, DatabaseID?)]> {
        self.migrators { migrator in
            migrator.previewRevertAllBatches().and(value: migrator.id)
        }.map {
            $0.flatMap { migrations, id in migrations.map { ($0, id) } }
        }
    }

    private func migrators<Result: Sendable>(
        _ handler: (DatabaseMigrator) -> EventLoopFuture<Result>
    ) -> EventLoopFuture<[Result]> {
        EventLoopFuture.whenAllSucceed(
            self.migrations.storage.withLockedValue { $0 }.map {
                handler(.init(id: $0, database: self.databaseFactory($0), migrations: $1, migrationLogLevel: self.migrationLogLevel))
            }, on: self.eventLoop)
    }
}

private final class DatabaseMigrator: Sendable {
    let migrations: [any Migration]
    let database: any Database
    let id: DatabaseID?
    let migrationLogLevel: Logger.Level

    init(id: DatabaseID?, database: any Database, migrations: [any Migration], migrationLogLevel: Logger.Level) {
        self.migrations = migrations
        self.database = database
        self.id = id
        self.migrationLogLevel = migrationLogLevel
    }

    // MARK: Setup

    func setupIfNeeded() -> EventLoopFuture<Void> {
        MigrationLog.migration.prepare(on: self.database)
            .map { self.preventUnstableNames() }
    }

    /// An unstable name is a name that is not the same every time migrations
    /// are run.
    ///
    /// For example, the default name for `Migrations` in private contexts
    /// will include an identifier that can change from one execution to the next.
    private func preventUnstableNames() {
        for migration in self.migrations
        where migration.name == migration.defaultName && migration.name.contains("$") {
            if migration.name.contains("unknown context at") {
                self.database.logger.critical(
                    "The migration at \(migration.name) is in a private context. Either explicitly give it a name by adding the `var name: String` property or make the migration `internal` or `public` instead of `private`."
                )
                fatalError("Private migrations not allowed")
            }
            self.database.logger.error(
                "The migration has an unexpected default name. Consider giving it an explicit name by adding a `var name: String` property before applying these migrations.",
                metadata: ["migration": .string(migration.name)])
        }
    }

    // MARK: Prepare

    func prepareBatch() -> EventLoopFuture<Void> {
        self.lastBatchNumber().flatMap { batch in
            self.unpreparedMigrations().flatMapWithEventLoop {
                $0.reduce($1.makeSucceededVoidFuture()) { future, migration in
                    future.flatMap { self.prepare(migration, batch: batch + 1) }
                }
            }
        }
    }

    // MARK: Revert

    func revertLastBatch() -> EventLoopFuture<Void> {
        self.lastBatchNumber().flatMap { self.revertBatch(number: $0) }
    }

    func revertBatch(number: Int) -> EventLoopFuture<Void> {
        self.preparedMigrations(batch: number).flatMapWithEventLoop {
            $0.reduce($1.makeSucceededVoidFuture()) { f, m in f.flatMap { self.revert(m) } }
        }
    }

    func revertAllBatches() -> EventLoopFuture<Void> {
        self.preparedMigrations().flatMapWithEventLoop { $0.reduce($1.makeSucceededVoidFuture()) { f, m in f.flatMap { self.revert(m) } } }
    }

    // MARK: Preview

    func previewPrepareBatch() -> EventLoopFuture<[any Migration]> {
        self.unpreparedMigrations()
    }

    func previewRevertLastBatch() -> EventLoopFuture<[any Migration]> {
        self.lastBatchNumber().flatMap { batch in
            self.preparedMigrations(batch: batch)
        }
    }

    func previewRevertBatch(number: Int) -> EventLoopFuture<[any Migration]> {
        self.preparedMigrations(batch: number)
    }

    func previewRevertAllBatches() -> EventLoopFuture<[any Migration]> {
        self.preparedMigrations()
    }

    // MARK: Private

    private func prepare(_ migration: any Migration, batch: Int) -> EventLoopFuture<Void> {
        self.database.logger.log(
            level: self.migrationLogLevel, "[Migrator] Starting prepare", metadata: ["migration": .string(migration.name)])

        return migration.prepare(on: self.database).flatMap {
            self.database.logger.log(
                level: self.migrationLogLevel, "[Migrator] Finished prepare", metadata: ["migration": .string(migration.name)])

            return MigrationLog(name: migration.name, batch: batch).save(on: self.database)
        }.flatMapErrorThrowing {
            self.database.logger.error(
                "[Migrator] Failed prepare", metadata: ["migration": .string(migration.name), "error": .string(String(reflecting: $0))])

            throw $0
        }
    }

    private func revert(_ migration: any Migration) -> EventLoopFuture<Void> {
        self.database.logger.log(
            level: self.migrationLogLevel, "[Migrator] Starting revert", metadata: ["migration": .string(migration.name)])

        return migration.revert(on: self.database).flatMap {
            self.database.logger.log(
                level: self.migrationLogLevel, "[Migrator] Finished revert", metadata: ["migration": .string(migration.name)])

            return MigrationLog.query(on: self.database).filter(\.$name == migration.name).delete()
        }.flatMapErrorThrowing {
            self.database.logger.error(
                "[Migrator] Failed revert", metadata: ["migration": .string(migration.name), "error": .string(String(reflecting: $0))])

            throw $0
        }
    }

    private func revertMigrationLog() -> EventLoopFuture<Void> {
        MigrationLog.migration.revert(on: self.database)
    }

    private func lastBatchNumber() -> EventLoopFuture<Int> {
        MigrationLog.query(on: self.database).sort(\.$batch, .descending).first().map { log in
            log?.batch ?? 0
        }
    }

    private func preparedMigrations() -> EventLoopFuture<[any Migration]> {
        MigrationLog.query(on: self.database).all().map { logs in
            self.migrations.filter { migration in
                logs.contains(where: { $0.name == migration.name })
            }.reversed()
        }
    }

    private func preparedMigrations(batch: Int) -> EventLoopFuture<[any Migration]> {
        MigrationLog.query(on: self.database).filter(\.$batch == batch).all().map { logs in
            self.migrations.filter { migration in
                logs.contains(where: { $0.name == migration.name })
            }.reversed()
        }
    }

    private func unpreparedMigrations() -> EventLoopFuture<[any Migration]> {
        MigrationLog.query(on: self.database).all().map { logs in
            self.migrations.compactMap { migration in
                if logs.contains(where: { $0.name == migration.name }) { return nil }
                return migration
            }
        }
    }
}
