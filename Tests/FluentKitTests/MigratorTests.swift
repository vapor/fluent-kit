@testable import FluentKit
import XCTest
import NIO

final class MigratorTests: XCTestCase {
    func testSingleMigration() throws {
        let migrations = Migrations()
        migrations.add(TestMigration(), to: .migrate1)

        let migrator = self.migrator(using: migrations)

        try migrator.setupIfNeeded().wait()
        try migrator.prepareBatch().wait()

        let logs = try MigrationLog.query(on: self.database(.migrate1)).all().wait()
        XCTAssertEqual(logs.count, 1)
        let log = try XCTUnwrap(logs.first)

        XCTAssertEqual(log.batch, 1)
        XCTAssertEqual(log.name, TestMigration().name)

        try XCTAssertEqual(MigrationLog.query(on: self.database(.migrate2)).all().wait().count, 0)
    }

    func testMultipleMigrations() throws {
        let migrations = Migrations()
        migrations.add(TestMigration(), to: .migrate1)
        migrations.add(TestMigration(), to: .migrate2)

        let migrator = self.migrator(using: migrations)

        try migrator.setupIfNeeded().wait()
        try migrator.prepareBatch().wait()

        let logs1 = try MigrationLog.query(on: self.database(.migrate1)).all().wait()
        XCTAssertEqual(logs1.count, 1)

        let log1 = try XCTUnwrap(logs1.first)
        XCTAssertEqual(log1.batch, 1)
        XCTAssertEqual(log1.name, TestMigration().name)


        let logs2 = try MigrationLog.query(on: self.database(.migrate2)).all().wait()
        XCTAssertEqual(logs2.count, 1)

        let log2 = try XCTUnwrap(logs1.first)
        XCTAssertEqual(log2.batch, 1)
        XCTAssertEqual(log2.name, TestMigration().name)
    }

    func testSubsequentMigration() throws {
        let migrations = Migrations()


        migrations.add(TestMigration(), to: .migrate1)
        let migrator1 = self.migrator(using: migrations)

        try migrator1.setupIfNeeded().wait()
        try migrator1.prepareBatch().wait()

        let logs1 = try MigrationLog.query(on: self.database(.migrate1)).all().wait()
        XCTAssertEqual(logs1.count, 1)

        let log1 = try XCTUnwrap(logs1.first)
        XCTAssertEqual(log1.batch, 1)
        XCTAssertEqual(log1.name, TestMigration().name)


        migrations.add(TestMigration(), to: .migrate2)
        let migrator2 = self.migrator(using: migrations)

        try migrator2.setupIfNeeded().wait()
        try migrator2.prepareBatch().wait()

        let logs2 = try MigrationLog.query(on: self.database(.migrate2)).all().wait()
        XCTAssertEqual(logs2.count, 1)

        let log2 = try XCTUnwrap(logs2.first)
        XCTAssertEqual(log2.batch, 1)
        XCTAssertEqual(log2.name, TestMigration().name)
    }


    var eventLoopGroup: EventLoopGroup!
    var threadPool: NIOThreadPool!
    var databases: Databases!


    func migrator(using migrations: Migrations) -> Migrator {
        return Migrator(
            databases: self.databases,
            migrations: migrations,
            logger: Logger(label: "codes.tests.vapor.migrations"),
            on: self.eventLoopGroup.next()
        )
    }

    func database(_ id: DatabaseID) -> Database {
        return self.databases.database(id, logger: Logger(label: "com.databases.\(id.string)"), on: self.eventLoopGroup.next())!
    }

    override func setUpWithError() throws {
        try super.setUpWithError()

        self.eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 1)
        self.threadPool = NIOThreadPool(numberOfThreads: 1)
        self.databases = Databases(threadPool: self.threadPool, on: self.eventLoopGroup)
    }

    override func tearDownWithError() throws {
        self.databases.shutdown()
        self.databases = nil

        try self.eventLoopGroup.syncShutdownGracefully()
        self.eventLoopGroup = nil

        try self.threadPool.syncShutdownGracefully()
        self.threadPool = nil

        try super.tearDownWithError()
    }
}

extension DatabaseID {
    static let migrate1 = DatabaseID(string: "migrate1")
    static let migrate2 = DatabaseID(string: "migrate2")
}

struct TestMigration: Migration {
    let name = "test_migration"

    func prepare(on database: Database) -> EventLoopFuture<Void> {
        return database.schema("foo")
            .field("id", .uuid, .identifier(auto: false))
            .field("bar", .string, .required)
            .field("baz", .int, .required)
            .field("fizz", .bool)
            .field("buzz", .double)
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        return database.schema("foo").delete()
    }
}
