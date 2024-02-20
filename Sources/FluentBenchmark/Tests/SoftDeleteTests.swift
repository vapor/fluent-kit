import FluentKit
import Foundation
import NIOCore
import XCTest

extension FluentBenchmarker {
    public func testSoftDelete() throws {
        try self.testSoftDelete_model()
        try self.testSoftDelete_query()
        try self.testSoftDelete_timestampUpdate()
        try self.testSoftDelete_onBulkDelete()
        try self.testSoftDelete_forceOnQuery()
        try self.testSoftDelete_parent()
    }
    
    private func testCounts(
        allCount: Int,
        realCount: Int,
        line: UInt = #line
    ) throws {
        let all = try Trash.query(on: self.database).all().wait()
        XCTAssertEqual(all.count, allCount, "excluding deleted", line: line)
        let real = try Trash.query(on: self.database).withDeleted().all().wait()
        XCTAssertEqual(real.count, realCount, "including deleted", line: line)
    }

    private func testSoftDelete_model() throws {
        try self.runTest(#function, [
            TrashMigration(),
        ]) {
            // save two users
            try Trash(contents: "A").save(on: self.database).wait()
            try Trash(contents: "B").save(on: self.database).wait()
            try testCounts(allCount: 2, realCount: 2)

            // soft-delete a user
            let a = try Trash.query(on: self.database).filter(\.$contents == "A").first().wait()!
            try a.delete(on: self.database).wait()
            try testCounts(allCount: 1, realCount: 2)

            // restore a soft-deleted user
            try a.restore(on: self.database).wait()
            try testCounts(allCount: 2, realCount: 2)

            // force-delete a user
            try a.delete(force: true, on: self.database).wait()
            try testCounts(allCount: 1, realCount: 1)
        }
    }

    private func testSoftDelete_query() throws {
        try self.runTest(#function, [
            TrashMigration()
        ]) {
            // a is scheduled for soft-deletion
            let a = Trash(contents: "a")
            a.deletedAt = Date(timeIntervalSinceNow: 50)
            try a.create(on: self.database).wait()

            // b is not soft-deleted
            let b = Trash(contents: "b")
            try b.create(on: self.database).wait()

            // select for non-existing c, expect 0
            // without proper query serialization this may
            // return a. see:
            // https://github.com/vapor/fluent-kit/pull/104
            let trash = try Trash.query(on: self.database)
                .filter(\.$contents == "c")
                .all().wait()
            XCTAssertEqual(trash.count, 0)
        }
    }

    private func testSoftDelete_timestampUpdate() throws {
        try self.runTest(#function, [
            TrashMigration()
        ]) {
            // Create soft-deletable model.
            let a = Trash(contents: "A")
            try a.create(on: self.database).wait()
            try XCTAssertEqual(Trash.query(on: self.database).all().wait().map(\.contents), ["A"])

            // Delete model and make sure it still exists, with its `.deletedAt` property set.
            try a.delete(on: self.database).wait()
            try XCTAssertEqual(Trash.query(on: self.database).all().wait().count, 0)
            try XCTAssertEqual(Trash.query(on: self.database).withDeleted().all().wait().map(\.contents), ["A"])
            let deletedAt = try XCTUnwrap(a.deletedAt).timeIntervalSince1970.rounded(.down)
            try XCTAssertEqual(
                Trash.query(on: self.database).withDeleted().first().wait()?.deletedAt?.timeIntervalSince1970.rounded(.down),
                deletedAt
            )

            // Delete all models
            sleep(1)
            try Trash.query(on: self.database).delete().wait()

            // Make sure the `.deletedAt` value doesn't change.
            try XCTAssertEqual(
                Trash.query(on: self.database).withDeleted().first().wait()?.deletedAt?.timeIntervalSince1970.rounded(.down),
                deletedAt
            )
        }
    }

    private func testSoftDelete_onBulkDelete() throws {
        try self.runTest(#function, [
            TrashMigration(),
        ]) {
            // save two users
            try Trash(contents: "A").save(on: self.database).wait()
            try Trash(contents: "B").save(on: self.database).wait()
            try testCounts(allCount: 2, realCount: 2)

            try Trash.query(on: self.database).delete().wait()
            try testCounts(allCount: 0, realCount: 2)
        }
    }
    
    private func testSoftDelete_forceOnQuery() throws {
        try self.runTest(#function, [
            TrashMigration()
        ]) {
            // save two users
            try Trash(contents: "A").save(on: self.database).wait()
            try Trash(contents: "B").save(on: self.database).wait()
            try testCounts(allCount: 2, realCount: 2)

            try Trash.query(on: self.database).delete(force: true).wait()
            try testCounts(allCount: 0, realCount: 0)
        }
    }

    // Tests eager load of @Parent relation that has been soft-deleted.
    private func testSoftDelete_parent() throws {
        final class Foo: Model {
            static let schema = "foos"

            @ID(key: .id)
            var id: UUID?

            @Parent(key: "bar")
            var bar: Bar

            init() { }
        }

        struct FooMigration: Migration {
            func prepare(on database: Database) -> EventLoopFuture<Void> {
                database.schema("foos")
                    .id()
                    .field("bar", .uuid, .required)
                    .create()
            }

            func revert(on database: Database) -> EventLoopFuture<Void> {
                database.schema("foos").delete()
            }
        }

        final class Bar: Model {
            static let schema = "bars"

            @ID(key: .id)
            var id: UUID?

            @Timestamp(key: "deleted_at", on: .delete)
            var deletedAt: Date?

            init() { }
        }

        struct BarMigration: Migration {
            func prepare(on database: Database) -> EventLoopFuture<Void> {
                database.schema("bars")
                    .id()
                    .field("deleted_at", .datetime)
                    .create()
            }

            func revert(on database: Database) -> EventLoopFuture<Void> {
                database.schema("bars").delete()
            }
        }

        try self.runTest(#function, [
            FooMigration(),
            BarMigration(),
        ]) {
            let bar1 = Bar()
            try bar1.create(on: self.database).wait()
            let bar2 = Bar()
            try bar2.create(on: self.database).wait()

            let foo1 = Foo()
            foo1.$bar.id = bar1.id!
            try foo1.create(on: self.database).wait()

            let foo2 = Foo()
            foo2.$bar.id = bar2.id!
            try foo2.create(on: self.database).wait()

            // test fetch
            let foos = try Foo.query(on: self.database).with(\.$bar).all().wait()
            XCTAssertEqual(foos.count, 2)
            XCTAssertNotNil(foos[0].$bar.value)
            XCTAssertNotNil(foos[1].$bar.value)

            // soft-delete bar 1
            try bar1.delete(on: self.database).wait()

            // test fetch again
            // this should throw an error now because one of the
            // parents is missing and the results cannot be loaded
            XCTAssertThrowsError(try Foo.query(on: self.database).with(\.$bar).all().wait()) { error in
                guard case let .missingParent(from, to, key, id) = error as? FluentError else {
                    return XCTFail("Expected FluentError.missingParent, but got \(error)")
                }
                XCTAssertEqual(from, "\(Foo.self)")
                XCTAssertEqual(to, "\(Bar.self)")
                XCTAssertEqual(key, "bar")
                XCTAssertEqual(id, "\(bar1.id!)")
            }
            
            XCTAssertNoThrow(try Foo.query(on: self.database).with(\.$bar, withDeleted: true).all().wait())
        }
    }
}

private final class Trash: Model {
    static let schema = "trash"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "contents")
    var contents: String

    @Timestamp(key: "deleted_at", on: .delete)
    var deletedAt: Date?

    init() { }

    init(id: UUID? = nil, contents: String, deletedAt: Date? = nil) {
        if let id = id {
            self.id = id
            self._id.exists = true
        }
        self.contents = contents
        self.deletedAt = deletedAt
    }
}

private struct TrashMigration: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema("trash")
            .field("id", .uuid, .identifier(auto: false), .custom("UNIQUE"))
            .field("contents", .string, .required)
            .field("deleted_at", .datetime)
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema("trash").delete()
    }
}
