import AsyncAlgorithms
import Foundation
import Logging
import NIOConcurrencyHelpers

public struct Migrator: Sendable {
    public let databaseFactory: @Sendable (DatabaseID?) -> (any Database)
    public let migrations: Migrations
    public let migrationLogLevel: Logger.Level

    public init(
        databases: Databases,
        migrations: Migrations,
        logger: Logger,
        migrationLogLevel: Logger.Level = .info
    ) {
        self.init(
            databaseFactory: { databases.database($0, logger: logger) },
            migrations: migrations,
            migrationLogLevel: migrationLogLevel
        )
    }

    public init(
        databaseFactory: @escaping @Sendable (DatabaseID?) -> (any Database),
        migrations: Migrations,
        migrationLogLevel: Logger.Level = .info
    ) {
        self.databaseFactory = databaseFactory
        self.migrations = migrations
        self.migrationLogLevel = migrationLogLevel
    }
    
    // MARK: Setup
    
    public func setupIfNeeded() async throws {
        _ = try await self.migrators() { try await $0.setupIfNeeded() }
    }
    
    // MARK: Prepare
    
    public func prepareBatch() async throws {
        _ = try await self.migrators() { try await $0.prepareBatch() }
    }
    
    // MARK: Revert
    
    public func revertLastBatch() async throws {
        _ = try await self.migrators() { try await $0.revertLastBatch() }
    }
    
    public func revertBatch(number: Int) async throws {
        _ = try await self.migrators() { try await $0.revertBatch(number: number) }
    }
    
    public func revertAllBatches() async throws {
        _ = try await self.migrators() { try await $0.revertAllBatches() }
    }
    
    // MARK: Preview
    
    public func previewPrepareBatch() async throws -> [(any Migration, DatabaseID?)] {
        try await self.migrators() { migrator in
            try await migrator.previewPrepareBatch().map { ($0, migrator.id) }
        }.flatMap { $0 }
    }
    
    public func previewRevertLastBatch() async throws -> [(any Migration, DatabaseID?)] {
        try await self.migrators() { migrator in
            try await migrator.previewRevertLastBatch().map { ($0, migrator.id) }
        }.flatMap { $0 }
    }
    
    public func previewRevertBatch(number: Int) async throws -> [(any Migration, DatabaseID?)] {
        try await self.migrators() { migrator in
            try await migrator.previewRevertBatch(number: number).map { ($0, migrator.id) }
        }.flatMap { $0 }
    }
    
    public func previewRevertAllBatches() async throws -> [(any Migration, DatabaseID?)] {
        try await self.migrators() { migrator in
            try await migrator.previewRevertAllBatches().map { ($0, migrator.id) }
        }.flatMap { $0 }
    }

    private func migrators<Result>(
        _ handler: (DatabaseMigrator) async throws -> Result
    ) async throws -> [Result] {
        var results: [Result] = []

        let migrations = self.migrations.storage.withLockedValue { $0 }
        for (id, migration) in migrations {
            results.append(try await handler(.init(id: id, database: self.databaseFactory(id), migrations: migration, migrationLogLevel: self.migrationLogLevel)))
        }
        return results
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

    func setupIfNeeded() async throws {
        try await MigrationLog.migration.prepare(on: self.database)
        self.preventUnstableNames()
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
            self.database.logger.error("The migration has an unexpected default name. Consider giving it an explicit name by adding a `var name: String` property before applying these migrations.", metadata: ["migration": .string(migration.name)])
        }
    }

    // MARK: Prepare

    func prepareBatch() async throws {
        let lastBatchNumber = try await self.lastBatchNumber()
        for migration in try await self.unpreparedMigrations() {
            try await self.prepare(migration, batch: lastBatchNumber + 1)
        }
    }

    // MARK: Revert

    func revertLastBatch() async throws {
        try await self.revertBatch(number: self.lastBatchNumber())
    }

    func revertBatch(number: Int) async throws {
        for migration in try await self.preparedMigrations(batch: number) {
            try await self.revert(migration)
        }
    }

    func revertAllBatches() async throws {
        for migration in try await self.preparedMigrations() {
            try await self.revert(migration)
        }
    }

    // MARK: Preview

    func previewPrepareBatch() async throws -> [any Migration] {
        try await self.unpreparedMigrations()
    }

    func previewRevertLastBatch() async throws -> [any Migration] {
        try await self.preparedMigrations(batch: self.lastBatchNumber())
    }

    func previewRevertBatch(number: Int) async throws -> [any Migration] {
        try await self.preparedMigrations(batch: number)
    }

    func previewRevertAllBatches() async throws -> [any Migration] {
        try await self.preparedMigrations()
    }

    // MARK: Private

    private func prepare(_ migration: any Migration, batch: Int) async throws {
        do {
            self.database.logger.log(level: self.migrationLogLevel, "[Migrator] Starting prepare", metadata: ["migration": .string(migration.name)])
            try await migration.prepare(on: self.database)
            self.database.logger.log(level: self.migrationLogLevel, "[Migrator] Finished prepare", metadata: ["migration": .string(migration.name)])
        } catch {
            self.database.logger.error("[Migrator] Failed prepare", metadata: ["migration": .string(migration.name), "error": .string(String(reflecting: error))])
            throw error
        }
        try await MigrationLog(name: migration.name, batch: batch).save(on: self.database)
    }

    private func revert(_ migration: any Migration) async throws {
        do {
            self.database.logger.log(level: self.migrationLogLevel, "[Migrator] Starting revert", metadata: ["migration": .string(migration.name)])
            try await migration.revert(on: self.database)
            self.database.logger.log(level: self.migrationLogLevel, "[Migrator] Finished revert", metadata: ["migration": .string(migration.name)])
        } catch {
            self.database.logger.error("[Migrator] Failed revert", metadata: ["migration": .string(migration.name), "error": .string(String(reflecting: error))])
            throw error
        }
        try await MigrationLog.query(on: self.database).filter(\.$name == migration.name).delete()
    }

    private func revertMigrationLog() async throws {
        try await MigrationLog.migration.revert(on: self.database)
    }

    private func lastBatchNumber() async throws -> Int {
        try await MigrationLog.query(on: self.database).sort(\.$batch, .descending).first()?.batch ?? 0
    }

    private func preparedMigrations() async throws -> [any Migration] {
        let logs = try await Array(MigrationLog.query(on: self.database).all())

        return self.migrations.filter { migration in
            logs.contains(where: { $0.name == migration.name })
        }.reversed()
    }

    private func preparedMigrations(batch: Int) async throws -> [any Migration] {
        let logs = try await Array(MigrationLog.query(on: self.database).filter(\.$batch == batch).all())

        return self.migrations.filter { migration in
            logs.contains(where: { $0.name == migration.name })
        }.reversed()
    }

    private func unpreparedMigrations() async throws -> [any Migration] {
        let logs = try await Array(MigrationLog.query(on: self.database).all())

        return self.migrations.compactMap { migration in
            if logs.contains(where: { $0.name == migration.name }) { return nil }
            return migration
        }
    }
}
