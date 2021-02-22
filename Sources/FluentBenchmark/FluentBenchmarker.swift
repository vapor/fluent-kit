import FluentKit
import Foundation
import NIO
import XCTest

public final class FluentBenchmarker {
    public let databases: Databases

    public var database: Database {
        self.databases.database(
            logger: .init(label: "codes.fluent.benchmarker"),
            on: self.databases.eventLoopGroup.next()
        )!
    }
    
    public init(databases: Databases) {
        precondition(databases.ids().count >= 2, "FluentBenchmarker Databases instance must have 2 or more registered databases")
        self.databases = databases
    }

    public func testAll() throws {
        try self.testAggregate()
        try self.testArray()
        try self.testBatch()
        try self.testChild()
        try self.testChildren()
        try self.testCodable()
        try self.testChunk()
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
        on database: Database? = nil,
        _ test: () throws -> ()
    ) throws {
        self.log("Running \(name)...")
        let database = database ?? self.database

        // Prepare migrations.
        for migration in migrations {
            try migration.prepare(on: database).wait()
        }

        var e: Error?
        do {
            try test()
        } catch {
            e = error
        }

        // Revert migrations
        for migration in migrations.reversed() {
            try migration.revert(on: database).wait()
        }

        if let error = e {
            throw error
        }
    }
    
    private func log(_ message: String) {
        self.database.logger.notice("[FluentBenchmark] \(message)")
    }
}
