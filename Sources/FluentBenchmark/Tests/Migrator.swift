extension FluentBenchmarker {
    public func testMigrator() throws {
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
                .all().wait()
                .map { $0.batch }
            XCTAssertEqual(logs, [1, 1, 2], "batch did not increment")

            try migrator.revertAllBatches().wait()

        }
    }

    public func testMigratorError() throws {
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
