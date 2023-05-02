import FluentKit
import Foundation
import XCTest

public final class FluentBenchmarker {
    public let databases: Databases
    public var database: any Database

    public init(databases: Databases) {
        precondition(databases.ids().count >= 2, "FluentBenchmarker Databases instance must have 2 or more registered databases")
        self.databases = databases
        self.database = self.databases.database(
            logger: .init(label: "codes.vapor.fluent.benchmarker"),
            on: self.databases.eventLoopGroup.any()
        )!
    }

    public func testAll() throws {
        try self.testAggregate()
        try self.testArray()
        try self.testBatch()
        try self.testChild()
        try self.testChildren()
        try self.testCodable()
        try self.testChunk()
        try self.testCompositeID()
        try self.testCRUD()
        try self.testEagerLoad()
        try self.testEnum()
        try self.testFilter()
        try self.testGroup()
        try self.testID()
        try self.testJoin()
        try self.testMiddleware()
        try self.testMigrator()
        try self.testModel()
        try self.testOptionalParent()
        try self.testPagination()
        try self.testParent()
        try self.testPerformance()
        try self.testRange()
        try self.testSchema()
        try self.testSet()
        try self.testSiblings()
        try self.testSoftDelete()
        try self.testSort()
        try self.testSQL()
        try self.testTimestamp()
        try self.testTransaction()
        try self.testUnique()
    }

    // MARK: Utilities

    internal func runTest(
        _ name: String, 
        _ migrations: [Migration], 
        _ test: () throws -> ()
    ) throws {
        try self.runTest(name, migrations, { _ in try test() })
    }
    
    internal func runTest(
        _ name: String,
        _ migrations: [Migration],
        _ test: (any Database) throws -> ()
    ) throws {
        // This re-initialization is required to make the middleware tests work thanks to ridiculous design flaws
        self.database = self.databases.database(
            logger: .init(label: "codes.vapor.fluent.benchmarker"),
            on: self.databases.eventLoopGroup.any()
        )!
        try self.runTest(name, migrations, on: self.database, test)
    }
    
    internal func runTest(
        _ name: String,
        _ migrations: [Migration],
        on database: any Database,
        _ test: (any Database) throws -> ()
    ) throws {
        database.logger.notice("Running \(name)...")

        // Prepare migrations.
        do {
            for migration in migrations {
                try migration.prepare(on: database).wait()
            }
        } catch {
            database.logger.error("\(name): Error: \(String(reflecting: error))")
            throw error
        }
        
        let result = Result { try test(database) }

        // Revert migrations
        do {
            for migration in migrations.reversed() {
                try migration.revert(on: database).wait()
            }
        } catch {
            // ignore revert errors if the test itself failed
            guard case .failure(_) = result else {
                database.logger.error("\(name): Error: \(String(reflecting: error))")
                throw error
            }
        }
        
        if case .failure(let error) = result {
            database.logger.error("\(name): Error: \(String(reflecting: error))")
            throw error
        }
    }
}
