extension FluentBenchmarker {
    public func testSoftDelete() throws {
        func testCounts(allCount: Int, realCount: Int) throws {
            let all = try Trash.query(on: self.database).all().wait()
            guard all.count == allCount else {
                XCTFail("all count should be \(allCount)")
                return
            }
            let real = try Trash.query(on: self.database).withDeleted().all().wait()
            guard real.count == realCount else {
                XCTFail("real count should be \(realCount)")
                return
            }
        }

        try runTest(#function, [
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

    public func testSoftDeleteWithQuery() throws {
        try runTest(#function, [
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
        database.schema(Trash.schema)
            .field("id", .uuid, .identifier(auto: false), .custom("UNIQUE"))
            .field("contents", .string, .required)
            .field("deleted_at", .datetime)
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema(Trash.schema).delete()
    }
}
