extension FluentBenchmarker {
    public func testMigrator() throws {
        try self.testMigrator_success()
        try self.testMigrator_error()
        try self.testMigrator_sequence()
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

            let database1 = try XCTUnwrap(
                self.databases.database(
                    databaseID.0,
                    logger: Logger(label: "codes.vapor.tests"),
                    on: self.databases.eventLoopGroup.next()
                )
            )
            let database2 = try XCTUnwrap(
                self.databases.database(
                    databaseID.1,
                    logger: Logger(label: "codes.vapor.tests"),
                    on: self.databases.eventLoopGroup.next()
                )
            )

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
            let log1 = try XCTUnwrap(logs1.first)
            XCTAssertEqual(log1.batch, 1)
            XCTAssertEqual(log1.name, "\(GalaxyMigration.self)")

            do {
                let count = try MigrationLog.query(on: database2).count().wait()

                // This is a valid state to enter. Unlike database in the SQL family,
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
            let log2 = try XCTUnwrap(logs2.first)
            XCTAssertEqual(log2.batch, 1)
            XCTAssertEqual(log2.name, "\(GalaxyMigration.self)")

            try XCTAssertEqual(MigrationLog.query(on: database1).count().wait(), 1)

            
            // Teardown
            try migrator.revertAllBatches().wait()
        }
    }
}

private struct ErrorMigration: Migration {
    init() { }

    struct Error: Swift.Error { }

    func prepare(on database: Database) -> EventLoopFuture<Void> {
        return database.eventLoop.makeFailedFuture(Error())
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        return database.eventLoop.makeSucceededFuture(())
    }
}
