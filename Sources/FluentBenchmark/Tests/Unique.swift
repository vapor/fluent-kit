extension FluentBenchmarker {
    public func testUniqueFields() throws {
        try self.runTest(#function, [
            FooMigration(),
        ]) {
            try Foo(bar: "a", baz: 1).save(on: self.database).wait()
            try Foo(bar: "a", baz: 2).save(on: self.database).wait()
            do {
                try Foo(bar: "a", baz: 1).save(on: self.database).wait()
                XCTFail("should have failed")
            } catch _ as DatabaseError {
                // pass
            }
        }
    }

    // https://github.com/vapor/fluent-kit/issues/112
    public func testDuplicatedUniquePropertyName() throws {
        try runTest(#function, [
            BarMigration(),
            BazMigration()
        ]) {
            //
        }
    }
}

private final class Foo: Model {
    static let schema = "foos"

    @ID(key: FluentBenchmarker.idKey)
    var id: UUID?

    @Field(key: "bar")
    var bar: String

    @Field(key: "baz")
    var baz: Int

    init() { }

    init(id: IDValue? = nil, bar: String, baz: Int) {
        self.id = id
        self.bar = bar
        self.baz = baz
    }
}

private struct FooMigration: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema("foos")
            .field("id", .uuid, .identifier(auto: false))
            .field("bar", .string, .required)
            .field("baz", .int, .required)
            .unique(on: "bar", "baz")
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema("foos").delete()
    }
}

private struct BarMigration: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema("bars")
            .field("name", .string)
            .unique(on: "name")
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema("bars").delete()
    }
}

private struct BazMigration: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema("bazs")
            .field("name", .string)
            .unique(on: "name")
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema("bazs").delete()
    }
}
