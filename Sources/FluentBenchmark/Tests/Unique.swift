extension FluentBenchmarker {
    public func testUniqueFields() throws {
        final class Foo: Model {
            static let schema = "foos"

            @ID(key: "id")
            var id: Int?

            @Field(key: "bar")
            var bar: String

            @Field(key: "baz")
            var baz: Int

            init() { }
            init(id: Int? = nil, bar: String, baz: Int) {
                self.id = id
                self.bar = bar
                self.baz = baz
            }
        }
        struct FooMigration: Migration {
            func prepare(on database: Database) -> EventLoopFuture<Void> {
                return database.schema("foos")
                    .field("id", .int, .identifier(auto: true))
                    .field("bar", .string, .required)
                    .field("baz", .int, .required)
                    .unique(on: "bar", "baz")
                    .create()
            }

            func revert(on database: Database) -> EventLoopFuture<Void> {
                return database.schema("foos").delete()
            }
        }
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
        struct Foo: Migration {
            func prepare(on database: Database) -> EventLoopFuture<Void> {
                database.schema("foos")
                    .field("name", .string)
                    .unique(on: "name")
                    .create()
            }

            func revert(on database: Database) -> EventLoopFuture<Void> {
                database.schema("foos").delete()
            }
        }
        struct Bar: Migration {
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
        try runTest(#function, [
            Foo(),
            Bar()
        ]) {
            //
        }
    }
}
