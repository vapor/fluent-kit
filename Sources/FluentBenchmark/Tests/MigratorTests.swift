import FluentKit
import Foundation
import NIOCore
import XCTest
import Logging

extension FluentBenchmarker {
    public func testMigrator() throws {
        try self.testMigrator_success()
        try self.testMigrator_error()
        try self.testMigrator_sequence()
        try self.testMigrator_addMultiple()
    }

    private func testMigrator_success() throws {
        try self.runTest(#function, []) {
            let migrations = Migrations()
            migrations.add(GalaxyMigration())
            migrations.add(StarMigration())

            let migrator = Migrator(
                databaseFactory: { _ in self.database },
                migrations: migrations,
                on: self.database.eventLoop
            )
            try migrator.setupIfNeeded().wait()
            try migrator.prepareBatch().wait()

            migrator.migrations.add(GalaxySeed())
            try migrator.prepareBatch().wait()

            let logs = try MigrationLog.query(on: self.database)
                .sort(\.$batch, .ascending)
                .all().wait()
                .map { $0.batch }
            XCTAssertEqual(logs, [1, 1, 2], "batch did not increment")

            try migrator.revertAllBatches().wait()
        }
    }

    private func testMigrator_error() throws {
        try self.runTest(#function, []) {
            let migrations = Migrations()
            migrations.add(GalaxyMigration())
            migrations.add(ErrorMigration())
            migrations.add(StarMigration())

            let migrator = Migrator(
                databaseFactory: { _ in self.database },
                migrations: migrations,
                on: self.database.eventLoop
            )
            try migrator.setupIfNeeded().wait()
            do {
                try migrator.prepareBatch().wait()
                XCTFail("Migration should have failed.")
            } catch {
                // success
            }
            try migrator.revertAllBatches().wait()
        }
    }

    private func testMigrator_sequence() throws {
        try self.runTest(#function, []) {

            // Setup
            let ids = Array(self.databases.ids())
            let databaseID = (ids[0], ids[1])

            let database1 = self.databases.database(
                databaseID.0,
                logger: Logger(label: "codes.vapor.tests"),
                on: self.databases.eventLoopGroup.next()
            )!
            let database2 = self.databases.database(
                databaseID.1,
                logger: Logger(label: "codes.vapor.tests"),
                on: self.databases.eventLoopGroup.next()
            )!

            let migrations = Migrations()


            // Migration #1
            migrations.add(GalaxyMigration(), to: databaseID.0)

            let migrator = Migrator(
                databases: self.databases,
                migrations: migrations,
                logger: Logger(label: "codes.vapor.tests"),
                on: self.databases.eventLoopGroup.next()
            )

            try migrator.setupIfNeeded().wait()
            try migrator.prepareBatch().wait()

            let logs1 = try MigrationLog.query(on: database1).all().wait()
            XCTAssertEqual(logs1.count, 1)
            XCTAssertEqual(logs1.first?.batch, 1)
            XCTAssertEqual(logs1.first?.name, String(reflecting: GalaxyMigration.self))

            do {
                let count = try MigrationLog.query(on: database2).count().wait()

                // This is a valid state to enter. Unlike databases in the SQL family,
                // some databases such as MongoDB won't throw an error if the table doesn't exist.
                XCTAssertEqual(count, 0)
            } catch {
                // This is a valid state to enter. A SQL database will throw an error
                // because the `_fluent_migrations` table on the `database2` database
                // will have not been created yet.
            }


            // Migration #2
            migrations.add(GalaxyMigration(), to: databaseID.1)

            try migrator.setupIfNeeded().wait()
            try migrator.prepareBatch().wait()

            let logs2 = try MigrationLog.query(on: database2).all().wait()
            XCTAssertEqual(logs2.count, 1)
            XCTAssertEqual(logs2.first?.batch, 1)
            XCTAssertEqual(logs2.first?.name, String(reflecting: GalaxyMigration.self))

            try XCTAssertEqual(MigrationLog.query(on: database1).count().wait(), 1)

            
            // Teardown
            try migrator.revertAllBatches().wait()
        }
    }

    private func testMigrator_addMultiple() throws {
        try self.runTest(#function, []) {
            let logger = Logger(label: "codes.vapor.tests")
            let databaseIds = Array(self.databases.ids()).prefix(2)
            let databases = databaseIds.map { self.databases.database($0, logger: logger, on: self.databases.eventLoopGroup.next())! }
            let migrations = Migrations()
            
            migrations.add([GalaxyMigration(), StarMigration(), GalaxySeed()], to: databaseIds[0])
            migrations.add(GalaxyMigration(), StarMigration(), PlanetMigration(), to: databaseIds[1])

            let migrator = Migrator(
                databases: self.databases,
                migrations: migrations,
                logger: Logger(label: "codes.vapor.tests"),
                on: self.databases.eventLoopGroup.next()
            )
            try migrator.setupIfNeeded().wait()
            try migrator.prepareBatch().wait()

            let logs1 = try MigrationLog.query(on: databases[0])
                .sort(\.$batch, .ascending)
                .all(\.$batch).wait()
            XCTAssertEqual(logs1, [1, 1, 1], "batch did not apply first three")

            let logs2 = try MigrationLog.query(on: databases[1])
                .sort(\.$batch, .ascending)
                .all(\.$batch).wait()
            XCTAssertEqual(logs2, [1, 1, 1], "batch did not apply second three")

            try migrator.revertAllBatches().wait()

            XCTAssertEqual(try MigrationLog.query(on: databases[0]).count().wait(), 0, "Revert of first batch was incomplete")
            XCTAssertEqual(try MigrationLog.query(on: databases[1]).count().wait(), 0, "Revert of second batch was incomplete")
        }
    }
}

internal struct ErrorMigration: Migration {
    init() { }

    struct Error: Swift.Error { }

    func prepare(on database: Database) -> EventLoopFuture<Void> {
        return database.eventLoop.makeFailedFuture(Error())
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        return database.eventLoop.makeSucceededFuture(())
    }
}
