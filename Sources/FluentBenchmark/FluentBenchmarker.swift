@testable import FluentKit
import Foundation
import NIO
import XCTest

public final class FluentBenchmarker {
    public let database: Database
    
    public init(database: Database) {
        self.database = database
    }

    public func testAll() throws {
        try self.testAggregates()
        try self.testArray()
        try self.testAsyncCreate()
        try self.testBatchCreate()
        try self.testBatchUpdate()
        try self.testChunkedFetch()
        try self.testCreate()
        try self.testCustomID()
        try self.testDelete()
        try self.testDuplicatedUniquePropertyName()
        try self.testEagerLoadChildren()
        try self.testEagerLoadChildrenJSON()
        try self.testEagerLoadParent()
        try self.testEagerLoadParentJSON()
        try self.testEmptyEagerLoadChildren()
        try self.testFieldFilter()
        try self.testGroup()
        try self.testIdentifierGeneration()
        try self.testJoin()
        try self.testJoinedFieldFilter()
        try self.testMigrator()
        try self.testMigratorError()
        try self.testModelMiddleware()
        try self.testMultipleJoinSameTable()
        try self.testMultipleSet()
        try self.testNestedModel()
        try self.testNewModelDecode()
        try self.testNonstandardIDKey()
        try self.testNullifyField()
        try self.testOptionalParent()
        try self.testPagination()
        try self.testParentGet()
        try self.testParentSerialization()
        try self.testPerformance()
        try self.testRange()
        try self.testRead()
        try self.testRelationMethods()
        try self.testSameChildrenFromKey()
        try self.testSiblingsAttach()
        try self.testSiblingsEagerLoad()
        try self.testSoftDelete()
        try self.testSoftDeleteWithQuery()
        try self.testSort()
        try self.testTimestampable()
        try self.testTransaction()
        try self.testUInt8BackedEnum()
        try self.testUUIDModel()
        try self.testUniqueFields()
        try self.testUpdate()
    }

    // MARK: Utilities

    internal func runTest(_ name: String, _ migrations: [Migration], _ test: () throws -> ()) throws {
        self.log("Running \(name)...")
        for migration in migrations {
            do {
                try migration.prepare(on: self.database).wait()
            } catch {
                self.log("Migration failed: \(error) ")
                self.log("Attempting to revert existing migrations...")
                try migration.revert(on: self.database).wait()
                try migration.prepare(on: self.database).wait()
            }
        }
        var e: Error?
        do {
            try test()
        } catch {
            e = error
        }
        for migration in migrations.reversed() {
            try migration.revert(on: self.database).wait()
        }
        if let error = e {
            throw error
        }
    }
    
    private func log(_ message: String) {
        print("[FluentBenchmark] \(message)")
    }
}
