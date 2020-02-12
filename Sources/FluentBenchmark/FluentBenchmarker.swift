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
        try self.testCreate()
        try self.testRead()
        try self.testUpdate()
        try self.testDelete()
        try self.testEagerLoadChildren()
        try self.testEagerLoadParent()
        try self.testEagerLoadParentJSON()
        try self.testEagerLoadChildrenJSON()
        try self.testMigrator()
        try self.testMigratorError()
        try self.testJoin()
        try self.testBatchCreate()
        try self.testBatchUpdate()
        try self.testNestedModel()
        try self.testAggregates()
        try self.testIdentifierGeneration()
        try self.testNullifyField()
        try self.testChunkedFetch()
        try self.testUniqueFields()
        try self.testAsyncCreate()
        try self.testSoftDelete()
        try self.testTimestampable()
        try self.testModelMiddleware()
        try self.testSort()
        try self.testUUIDModel()
        try self.testNewModelDecode()
        try self.testSiblingsAttach()
        try self.testSiblingsEagerLoad()
        try self.testParentGet()
        try self.testParentSerialization()
        try self.testMultipleJoinSameTable()
        try self.testOptionalParent()
        try self.testFieldFilter()
        try self.testJoinedFieldFilter()
        try self.testSameChildrenFromKey()
        try self.testArray()
        try self.testPerformance()
        try self.testSoftDeleteWithQuery()
        try self.testDuplicatedUniquePropertyName()
        try self.testEmptyEagerLoadChildren()
        try self.testUInt8BackedEnum()
        try self.testRange()
        try self.testCustomID()
        try self.testMultipleSet()
        try self.testRelationMethods()
        try self.testGroup()
    }

    // MARK: Utilities
    
    struct Failure: Error {
        let reason: String
        let line: UInt
        let file: StaticString
        
        init(_ reason: String, line: UInt = #line, file: StaticString = #file) {
            self.reason = reason
            self.line = line
            self.file = file
        }
    }
    
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
        } catch let failure as Failure {
            XCTFail(failure.reason, file: failure.file, line: failure.line)
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
